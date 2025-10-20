// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenVesting {
    address public beneficiary;
    address public owner;
    uint256 public totalTokens;
    uint256 public releasedTokens;
    uint256 public startTime;
    uint256 public vestingDuration;
    uint256 public cliffDuration;
    
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary, uint256 refundAmount);
    
    constructor(
        address _beneficiary,
        uint256 _totalTokens,
        uint256 _vestingDurationInDays,
        uint256 _cliffDurationInDays
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_totalTokens > 0, "Total tokens must be greater than zero");
        require(_vestingDurationInDays > 0, "Vesting duration must be greater than zero");
        require(_cliffDurationInDays <= _vestingDurationInDays, "Cliff cannot exceed vesting duration");
        
        owner = msg.sender;
        beneficiary = _beneficiary;
        totalTokens = _totalTokens;
        releasedTokens = 0;
        startTime = block.timestamp;
        vestingDuration = _vestingDurationInDays * 1 days;
        cliffDuration = _cliffDurationInDays * 1 days;
    }
    
    function release() external {
        require(msg.sender == beneficiary, "Only beneficiary can release tokens");
        
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "No tokens available for release");
        
        releasedTokens += unreleased;
        
        (bool success, ) = beneficiary.call{value: unreleased}("");
        require(success, "Transfer failed");
        
        emit TokensReleased(beneficiary, unreleased);
    }
    
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - releasedTokens;
    }
    
    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime + cliffDuration) {
            return 0;
        } else if (block.timestamp >= startTime + vestingDuration) {
            return totalTokens;
        } else {
            uint256 timeVested = block.timestamp - startTime;
            return (totalTokens * timeVested) / vestingDuration;
        }
    }
    
    function fundVesting() external payable {
        require(msg.sender == owner, "Only owner can fund vesting");
        require(msg.value > 0, "Must send tokens to fund vesting");
    }
    
    function revoke() external {
        require(msg.sender == owner, "Only owner can revoke");
        
        uint256 unreleased = releasableAmount();
        if (unreleased > 0) {
            releasedTokens += unreleased;
            (bool success1, ) = beneficiary.call{value: unreleased}("");
            require(success1, "Transfer to beneficiary failed");
            emit TokensReleased(beneficiary, unreleased);
        }
        
        uint256 refund = address(this).balance;
        if (refund > 0) {
            (bool success2, ) = owner.call{value: refund}("");
            require(success2, "Refund to owner failed");
            emit VestingRevoked(beneficiary, refund);
        }
    }
    
    function getVestingInfo() external view returns (
        address _beneficiary,
        uint256 _totalTokens,
        uint256 _releasedTokens,
        uint256 _releasableTokens,
        uint256 _startTime,
        uint256 _vestingDuration,
        uint256 _cliffDuration
    ) {
        return (
            beneficiary,
            totalTokens,
            releasedTokens,
            releasableAmount(),
            startTime,
            vestingDuration,
            cliffDuration
        );
    }
    
    receive() external payable {}
}
