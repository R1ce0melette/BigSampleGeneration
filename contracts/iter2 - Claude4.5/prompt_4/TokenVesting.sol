// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public beneficiary;
    address public owner;
    IERC20 public token;
    
    uint256 public startTime;
    uint256 public cliff;
    uint256 public duration;
    uint256 public totalTokens;
    uint256 public releasedTokens;
    
    event TokensReleased(uint256 amount);
    event VestingRevoked();
    
    bool public revoked;
    
    constructor(
        address _beneficiary,
        address _token,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint256 _totalTokens
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_token != address(0), "Token cannot be zero address");
        require(_vestingDuration > 0, "Duration must be greater than 0");
        require(_totalTokens > 0, "Total tokens must be greater than 0");
        
        beneficiary = _beneficiary;
        owner = msg.sender;
        token = IERC20(_token);
        startTime = _startTime;
        cliff = _startTime + _cliffDuration;
        duration = _vestingDuration;
        totalTokens = _totalTokens;
        releasedTokens = 0;
        revoked = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary can call this function");
        _;
    }
    
    function release() external onlyBeneficiary {
        require(!revoked, "Vesting has been revoked");
        
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "No tokens available for release");
        
        releasedTokens += unreleased;
        
        require(token.transfer(beneficiary, unreleased), "Token transfer failed");
        
        emit TokensReleased(unreleased);
    }
    
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - releasedTokens;
    }
    
    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= startTime + duration || revoked) {
            return totalTokens;
        } else {
            uint256 timeVested = block.timestamp - startTime;
            return (totalTokens * timeVested) / duration;
        }
    }
    
    function revoke() external onlyOwner {
        require(!revoked, "Vesting already revoked");
        
        revoked = true;
        
        uint256 unreleased = releasableAmount();
        if (unreleased > 0) {
            releasedTokens += unreleased;
            require(token.transfer(beneficiary, unreleased), "Token transfer failed");
        }
        
        uint256 refund = token.balanceOf(address(this));
        if (refund > 0) {
            require(token.transfer(owner, refund), "Refund transfer failed");
        }
        
        emit VestingRevoked();
    }
    
    function getVestingInfo() external view returns (
        address _beneficiary,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _duration,
        uint256 _totalTokens,
        uint256 _releasedTokens,
        uint256 _releasableAmount,
        bool _revoked
    ) {
        return (
            beneficiary,
            startTime,
            cliff,
            duration,
            totalTokens,
            releasedTokens,
            releasableAmount(),
            revoked
        );
    }
}
