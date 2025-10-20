// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenVesting
 * @dev A token vesting contract that releases tokens gradually over time to a beneficiary
 */
contract TokenVesting {
    // Beneficiary of the vested tokens
    address public beneficiary;
    
    // Owner/admin of the contract
    address public owner;
    
    // Start time of the vesting period
    uint256 public startTime;
    
    // Duration of the vesting period in seconds
    uint256 public vestingDuration;
    
    // Total amount of tokens to be vested
    uint256 public totalTokens;
    
    // Amount of tokens already released
    uint256 public tokensReleased;
    
    // Events
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingInitialized(address indexed beneficiary, uint256 totalTokens, uint256 startTime, uint256 duration);
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);
    
    /**
     * @dev Constructor to initialize the vesting contract
     * @param _beneficiary The address that will receive the vested tokens
     * @param _startTime The time when vesting starts (unix timestamp)
     * @param _vestingDuration The duration of the vesting period in seconds
     */
    constructor(address _beneficiary, uint256 _startTime, uint256 _vestingDuration) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_vestingDuration > 0, "Vesting duration must be greater than 0");
        require(_startTime >= block.timestamp, "Start time cannot be in the past");
        
        owner = msg.sender;
        beneficiary = _beneficiary;
        startTime = _startTime;
        vestingDuration = _vestingDuration;
    }
    
    /**
     * @dev Deposit tokens into the vesting contract
     * Requirements:
     * - Only owner can deposit
     * - Tokens can only be deposited once
     */
    function depositTokens() external payable {
        require(msg.sender == owner, "Only owner can deposit tokens");
        require(totalTokens == 0, "Tokens already deposited");
        require(msg.value > 0, "Must deposit tokens");
        
        totalTokens = msg.value;
        
        emit VestingInitialized(beneficiary, totalTokens, startTime, vestingDuration);
    }
    
    /**
     * @dev Calculate the amount of tokens that have vested
     * @return The amount of tokens that have vested
     */
    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp >= startTime + vestingDuration) {
            return totalTokens;
        } else {
            uint256 timeElapsed = block.timestamp - startTime;
            return (totalTokens * timeElapsed) / vestingDuration;
        }
    }
    
    /**
     * @dev Calculate the amount of tokens that can be released
     * @return The amount of tokens available for release
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - tokensReleased;
    }
    
    /**
     * @dev Release vested tokens to the beneficiary
     * Requirements:
     * - Only beneficiary can release tokens
     * - There must be tokens available to release
     */
    function release() external {
        require(msg.sender == beneficiary, "Only beneficiary can release tokens");
        
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens available for release");
        
        tokensReleased += amount;
        
        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit TokensReleased(beneficiary, amount);
    }
    
    /**
     * @dev Change the beneficiary address (only owner)
     * @param newBeneficiary The new beneficiary address
     * Requirements:
     * - Only owner can change beneficiary
     * - New beneficiary cannot be zero address
     */
    function changeBeneficiary(address newBeneficiary) external {
        require(msg.sender == owner, "Only owner can change beneficiary");
        require(newBeneficiary != address(0), "New beneficiary cannot be zero address");
        
        address oldBeneficiary = beneficiary;
        beneficiary = newBeneficiary;
        
        emit BeneficiaryChanged(oldBeneficiary, newBeneficiary);
    }
    
    /**
     * @dev Get vesting schedule information
     * @return _beneficiary The beneficiary address
     * @return _totalTokens Total tokens being vested
     * @return _tokensReleased Tokens already released
     * @return _vestedAmount Tokens currently vested
     * @return _releasableAmount Tokens available for release
     * @return _startTime Vesting start time
     * @return _vestingDuration Vesting duration
     */
    function getVestingInfo() external view returns (
        address _beneficiary,
        uint256 _totalTokens,
        uint256 _tokensReleased,
        uint256 _vestedAmount,
        uint256 _releasableAmount,
        uint256 _startTime,
        uint256 _vestingDuration
    ) {
        return (
            beneficiary,
            totalTokens,
            tokensReleased,
            vestedAmount(),
            releasableAmount(),
            startTime,
            vestingDuration
        );
    }
    
    /**
     * @dev Get the remaining time until vesting is complete
     * @return The remaining time in seconds, or 0 if vesting is complete
     */
    function getRemainingTime() external view returns (uint256) {
        uint256 endTime = startTime + vestingDuration;
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }
}
