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
    
    bool public revoked;
    
    // Events
    event TokensReleased(uint256 amount);
    event VestingRevoked();
    
    /**
     * @dev Constructor to initialize the vesting schedule
     * @param _beneficiary Address of the beneficiary to whom vested tokens are transferred
     * @param _cliffDuration Duration in seconds of the cliff period
     * @param _duration Total duration in seconds of the vesting period
     */
    constructor(
        address _beneficiary,
        uint256 _cliffDuration,
        uint256 _duration
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_duration > 0, "Duration must be greater than 0");
        require(_cliffDuration <= _duration, "Cliff must be less than or equal to duration");
        
        owner = msg.sender;
        beneficiary = _beneficiary;
        startTime = block.timestamp;
        cliff = startTime + _cliffDuration;
        duration = _duration;
        revoked = false;
    }
    
    /**
     * @dev Allows the owner to fund the vesting contract with tokens (ETH in this case)
     */
    function fundVesting() external payable {
        require(msg.sender == owner, "Only owner can fund vesting");
        require(msg.value > 0, "Must send some tokens");
        
        totalTokens += msg.value;
    }
    
    /**
     * @dev Releases vested tokens to the beneficiary
     */
    function release() external {
        require(!revoked, "Vesting has been revoked");
        require(block.timestamp >= cliff, "Cliff period not reached");
        
        uint256 unreleased = _releasableAmount();
        require(unreleased > 0, "No tokens available for release");
        
        tokensReleased += unreleased;
        
        (bool success, ) = beneficiary.call{value: unreleased}("");
        require(success, "Transfer failed");
        
        emit TokensReleased(unreleased);
    }
    
    /**
     * @dev Allows the owner to revoke the vesting
     * Transfers already vested tokens to beneficiary and remaining tokens back to owner
     */
    function revoke() external {
        require(msg.sender == owner, "Only owner can revoke");
        require(!revoked, "Vesting already revoked");
        
        revoked = true;
        
        uint256 unreleased = _releasableAmount();
        uint256 refund = totalTokens - tokensReleased - unreleased;
        
        if (unreleased > 0) {
            tokensReleased += unreleased;
            (bool success1, ) = beneficiary.call{value: unreleased}("");
            require(success1, "Transfer to beneficiary failed");
        }
        
        if (refund > 0) {
            (bool success2, ) = owner.call{value: refund}("");
            require(success2, "Refund to owner failed");
        }
        
        emit VestingRevoked();
    }
    
    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet
     * @return The amount of tokens that can be released
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount() - tokensReleased;
    }
    
    /**
     * @dev Calculates the amount that has already vested
     * @return The amount of tokens that have vested
     */
    function _vestedAmount() private view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= startTime + duration || revoked) {
            return totalTokens;
        } else {
            return (totalTokens * (block.timestamp - startTime)) / duration;
        }
    }
    
    /**
     * @dev Returns the amount of tokens that can be released
     * @return The releasable amount
     */
    function getReleasableAmount() external view returns (uint256) {
        return _releasableAmount();
    }
    
    /**
     * @dev Returns the amount of tokens that have already vested
     * @return The vested amount
     */
    function getVestedAmount() external view returns (uint256) {
        return _vestedAmount();
    }
    
    /**
     * @dev Returns the total balance of the contract
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns the time remaining until the cliff
     * @return The time remaining in seconds, or 0 if cliff has passed
     */
    function getTimeUntilCliff() external view returns (uint256) {
        if (block.timestamp >= cliff) {
            return 0;
        }
        return cliff - block.timestamp;
    }
    
    /**
     * @dev Returns the time remaining until full vesting
     * @return The time remaining in seconds, or 0 if fully vested
     */
    function getTimeUntilFullyVested() external view returns (uint256) {
        uint256 endTime = startTime + duration;
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }
}
