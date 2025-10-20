// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public beneficiary;
    address public owner;
    IERC20 public token;
    
    uint256 public start;
    uint256 public cliff;
    uint256 public duration;
    uint256 public totalAmount;
    uint256 public released;
    
    bool public revocable;
    bool public revoked;
    
    // Events
    event TokensReleased(uint256 amount);
    event VestingRevoked();
    
    /**
     * @dev Constructor to initialize the vesting schedule
     * @param _beneficiary Address of the beneficiary to whom vested tokens are transferred
     * @param _token Address of the ERC20 token contract
     * @param _start Start time of the vesting period (unix timestamp)
     * @param _cliffDuration Duration in seconds of the cliff period
     * @param _duration Total duration of the vesting period in seconds
     * @param _totalAmount Total amount of tokens to be vested
     * @param _revocable Whether the vesting is revocable by the owner
     */
    constructor(
        address _beneficiary,
        address _token,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration,
        uint256 _totalAmount,
        bool _revocable
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_token != address(0), "Token cannot be zero address");
        require(_duration > 0, "Duration must be greater than 0");
        require(_totalAmount > 0, "Total amount must be greater than 0");
        require(_cliffDuration <= _duration, "Cliff is longer than duration");
        
        beneficiary = _beneficiary;
        token = IERC20(_token);
        owner = msg.sender;
        start = _start;
        cliff = _start + _cliffDuration;
        duration = _duration;
        totalAmount = _totalAmount;
        revocable = _revocable;
        revoked = false;
        released = 0;
    }
    
    /**
     * @dev Release vested tokens to the beneficiary
     */
    function release() external {
        require(!revoked, "Vesting has been revoked");
        
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "No tokens are due for release");
        
        released += unreleased;
        
        require(token.transfer(beneficiary, unreleased), "Token transfer failed");
        
        emit TokensReleased(unreleased);
    }
    
    /**
     * @dev Revoke the vesting schedule (only if revocable)
     */
    function revoke() external {
        require(msg.sender == owner, "Only owner can revoke");
        require(revocable, "Vesting is not revocable");
        require(!revoked, "Vesting already revoked");
        
        // Release any vested tokens first
        uint256 unreleased = releasableAmount();
        if (unreleased > 0) {
            released += unreleased;
            require(token.transfer(beneficiary, unreleased), "Token transfer failed");
            emit TokensReleased(unreleased);
        }
        
        // Return remaining tokens to owner
        uint256 remaining = totalAmount - released;
        if (remaining > 0) {
            require(token.transfer(owner, remaining), "Token transfer to owner failed");
        }
        
        revoked = true;
        emit VestingRevoked();
    }
    
    /**
     * @dev Calculate the amount of tokens that can be released
     * @return The amount of releasable tokens
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - released;
    }
    
    /**
     * @dev Calculate the amount of tokens that have vested
     * @return The amount of vested tokens
     */
    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration || revoked) {
            return totalAmount;
        } else {
            return (totalAmount * (block.timestamp - start)) / duration;
        }
    }
    
    /**
     * @dev Get the vesting schedule details
     * @return _beneficiary The beneficiary address
     * @return _start The start timestamp
     * @return _cliff The cliff timestamp
     * @return _duration The total vesting duration
     * @return _totalAmount The total amount to be vested
     * @return _released The amount already released
     * @return _revocable Whether the vesting is revocable
     * @return _revoked Whether the vesting has been revoked
     */
    function getVestingDetails() external view returns (
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _totalAmount,
        uint256 _released,
        bool _revocable,
        bool _revoked
    ) {
        return (
            beneficiary,
            start,
            cliff,
            duration,
            totalAmount,
            released,
            revocable,
            revoked
        );
    }
}
