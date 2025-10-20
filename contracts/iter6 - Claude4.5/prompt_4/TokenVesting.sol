// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenVesting
 * @dev A token vesting contract that releases tokens gradually over time to a beneficiary
 */
contract TokenVesting {
    address public beneficiary;
    address public owner;
    
    uint256 public totalTokens;
    uint256 public tokensReleased;
    uint256 public startTime;
    uint256 public cliff;
    uint256 public duration;
    
    bool public revocable;
    bool public revoked;
    
    // Events
    event TokensReleased(uint256 amount);
    event VestingRevoked();
    
    /**
     * @dev Constructor to initialize the vesting schedule
     * @param _beneficiary Address that will receive the vested tokens
     * @param _startTime Start time of the vesting period (unix timestamp)
     * @param _cliff Duration in seconds of the cliff period
     * @param _duration Duration in seconds of the total vesting period
     * @param _revocable Whether the vesting is revocable by the owner
     */
    constructor(
        address _beneficiary,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    ) payable {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_cliff <= _duration, "Cliff must be less than or equal to duration");
        require(_duration > 0, "Duration must be greater than 0");
        require(_startTime > 0, "Start time must be greater than 0");
        
        owner = msg.sender;
        beneficiary = _beneficiary;
        startTime = _startTime;
        cliff = _cliff;
        duration = _duration;
        revocable = _revocable;
        revoked = false;
        
        totalTokens = msg.value;
        tokensReleased = 0;
    }
    
    /**
     * @dev Release vested tokens to the beneficiary
     * Can be called by anyone, but tokens are always sent to beneficiary
     */
    function release() external {
        require(!revoked, "Vesting has been revoked");
        
        uint256 unreleased = getReleasableAmount();
        require(unreleased > 0, "No tokens available for release");
        
        tokensReleased += unreleased;
        
        (bool success, ) = beneficiary.call{value: unreleased}("");
        require(success, "Transfer failed");
        
        emit TokensReleased(unreleased);
    }
    
    /**
     * @dev Revoke the vesting schedule
     * Can only be called by owner if vesting is revocable
     * Unreleased tokens are returned to the owner
     */
    function revoke() external {
        require(msg.sender == owner, "Only owner can revoke");
        require(revocable, "Vesting is not revocable");
        require(!revoked, "Vesting already revoked");
        
        // Calculate and release any vested tokens first
        uint256 unreleased = getReleasableAmount();
        if (unreleased > 0) {
            tokensReleased += unreleased;
            (bool success, ) = beneficiary.call{value: unreleased}("");
            require(success, "Transfer to beneficiary failed");
            emit TokensReleased(unreleased);
        }
        
        // Return remaining tokens to owner
        uint256 refund = totalTokens - tokensReleased;
        if (refund > 0) {
            (bool success, ) = owner.call{value: refund}("");
            require(success, "Transfer to owner failed");
        }
        
        revoked = true;
        emit VestingRevoked();
    }
    
    /**
     * @dev Calculate the amount of tokens that can be released at the current time
     * @return The amount of releasable tokens
     */
    function getReleasableAmount() public view returns (uint256) {
        return getVestedAmount() - tokensReleased;
    }
    
    /**
     * @dev Calculate the total amount of tokens that have vested by current time
     * @return The amount of vested tokens
     */
    function getVestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime + cliff) {
            // Before cliff, no tokens vested
            return 0;
        } else if (block.timestamp >= startTime + duration || revoked) {
            // After duration or if revoked, all tokens vested
            return totalTokens;
        } else {
            // During vesting period, linear vesting
            uint256 timeVested = block.timestamp - startTime;
            return (totalTokens * timeVested) / duration;
        }
    }
    
    /**
     * @dev Get the remaining tokens that are still locked
     * @return The amount of locked tokens
     */
    function getRemainingTokens() external view returns (uint256) {
        return totalTokens - tokensReleased;
    }
    
    /**
     * @dev Get the time remaining until the vesting is complete
     * @return The remaining time in seconds, or 0 if vesting is complete
     */
    function getRemainingTime() external view returns (uint256) {
        uint256 endTime = startTime + duration;
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }
    
    /**
     * @dev Check if the cliff period has passed
     * @return True if cliff has passed, false otherwise
     */
    function isCliffPassed() external view returns (bool) {
        return block.timestamp >= startTime + cliff;
    }
    
    /**
     * @dev Get vesting schedule information
     * @return _beneficiary The beneficiary address
     * @return _totalTokens The total tokens in the vesting schedule
     * @return _tokensReleased The tokens already released
     * @return _startTime The start time of vesting
     * @return _cliff The cliff duration
     * @return _duration The total duration
     * @return _revocable Whether the vesting is revocable
     * @return _revoked Whether the vesting has been revoked
     */
    function getVestingInfo() external view returns (
        address _beneficiary,
        uint256 _totalTokens,
        uint256 _tokensReleased,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable,
        bool _revoked
    ) {
        return (
            beneficiary,
            totalTokens,
            tokensReleased,
            startTime,
            cliff,
            duration,
            revocable,
            revoked
        );
    }
}
