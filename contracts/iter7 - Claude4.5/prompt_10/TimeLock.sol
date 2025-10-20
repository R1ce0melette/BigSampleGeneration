// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeLock
 * @dev A contract that allows users to lock their ETH for a period and earn a fixed interest when unlocked
 */
contract TimeLock {
    // Lock structure
    struct Lock {
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 interestRate; // Interest rate in basis points (e.g., 500 = 5%)
        bool withdrawn;
    }
    
    // State variables
    mapping(address => Lock[]) public userLocks;
    uint256 public defaultInterestRate = 500; // 5% default interest rate
    address public owner;
    
    // Events
    event ETHLocked(address indexed user, uint256 indexed lockIndex, uint256 amount, uint256 unlockTime, uint256 interestRate);
    event ETHUnlocked(address indexed user, uint256 indexed lockIndex, uint256 amount, uint256 interest, uint256 total);
    event InterestRateUpdated(uint256 oldRate, uint256 newRate);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    /**
     * @dev Constructor sets the contract owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Lock ETH for a specified duration
     * @param lockDurationInDays The duration to lock ETH in days
     * @return lockIndex The index of the created lock
     */
    function lockETH(uint256 lockDurationInDays) external payable returns (uint256) {
        require(msg.value > 0, "Must send ETH to lock");
        require(lockDurationInDays > 0, "Lock duration must be greater than 0");
        
        uint256 unlockTime = block.timestamp + (lockDurationInDays * 1 days);
        
        Lock memory newLock = Lock({
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            interestRate: defaultInterestRate,
            withdrawn: false
        });
        
        userLocks[msg.sender].push(newLock);
        uint256 lockIndex = userLocks[msg.sender].length - 1;
        
        emit ETHLocked(msg.sender, lockIndex, msg.value, unlockTime, defaultInterestRate);
        
        return lockIndex;
    }
    
    /**
     * @dev Lock ETH with a custom interest rate (only owner can set custom rate)
     * @param user The user address
     * @param lockDurationInDays The duration to lock ETH in days
     * @param customInterestRate The custom interest rate in basis points
     * @return lockIndex The index of the created lock
     */
    function lockETHWithCustomRate(address user, uint256 lockDurationInDays, uint256 customInterestRate) external payable onlyOwner returns (uint256) {
        require(msg.value > 0, "Must send ETH to lock");
        require(lockDurationInDays > 0, "Lock duration must be greater than 0");
        require(user != address(0), "Invalid user address");
        
        uint256 unlockTime = block.timestamp + (lockDurationInDays * 1 days);
        
        Lock memory newLock = Lock({
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            interestRate: customInterestRate,
            withdrawn: false
        });
        
        userLocks[user].push(newLock);
        uint256 lockIndex = userLocks[user].length - 1;
        
        emit ETHLocked(user, lockIndex, msg.value, unlockTime, customInterestRate);
        
        return lockIndex;
    }
    
    /**
     * @dev Unlock ETH and withdraw with interest
     * @param lockIndex The index of the lock to unlock
     */
    function unlock(uint256 lockIndex) external {
        require(lockIndex < userLocks[msg.sender].length, "Invalid lock index");
        Lock storage userLock = userLocks[msg.sender][lockIndex];
        
        require(!userLock.withdrawn, "Already withdrawn");
        require(block.timestamp >= userLock.unlockTime, "Lock period not yet completed");
        
        uint256 principal = userLock.amount;
        uint256 interest = calculateInterest(principal, userLock.interestRate);
        uint256 totalAmount = principal + interest;
        
        userLock.withdrawn = true;
        
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed");
        
        emit ETHUnlocked(msg.sender, lockIndex, principal, interest, totalAmount);
    }
    
    /**
     * @dev Calculate interest for a given amount and rate
     * @param amount The principal amount
     * @param interestRate The interest rate in basis points
     * @return The interest amount
     */
    function calculateInterest(uint256 amount, uint256 interestRate) public pure returns (uint256) {
        return (amount * interestRate) / 10000;
    }
    
    /**
     * @dev Get lock details for a user
     * @param user The user address
     * @param lockIndex The index of the lock
     * @return amount The locked amount
     * @return lockTime The lock timestamp
     * @return unlockTime The unlock timestamp
     * @return interestRate The interest rate
     * @return withdrawn Whether the lock has been withdrawn
     * @return interest The interest amount
     */
    function getLockDetails(address user, uint256 lockIndex) external view returns (
        uint256 amount,
        uint256 lockTime,
        uint256 unlockTime,
        uint256 interestRate,
        bool withdrawn,
        uint256 interest
    ) {
        require(lockIndex < userLocks[user].length, "Invalid lock index");
        Lock memory userLock = userLocks[user][lockIndex];
        
        uint256 interestAmount = calculateInterest(userLock.amount, userLock.interestRate);
        
        return (
            userLock.amount,
            userLock.lockTime,
            userLock.unlockTime,
            userLock.interestRate,
            userLock.withdrawn,
            interestAmount
        );
    }
    
    /**
     * @dev Get the number of locks for a user
     * @param user The user address
     * @return The number of locks
     */
    function getUserLockCount(address user) external view returns (uint256) {
        return userLocks[user].length;
    }
    
    /**
     * @dev Get all locks for the caller
     * @return Array of all locks for msg.sender
     */
    function getMyLocks() external view returns (Lock[] memory) {
        return userLocks[msg.sender];
    }
    
    /**
     * @dev Check if a lock can be unlocked
     * @param user The user address
     * @param lockIndex The index of the lock
     * @return True if the lock can be unlocked, false otherwise
     */
    function canUnlock(address user, uint256 lockIndex) external view returns (bool) {
        if (lockIndex >= userLocks[user].length) {
            return false;
        }
        
        Lock memory userLock = userLocks[user][lockIndex];
        return !userLock.withdrawn && block.timestamp >= userLock.unlockTime;
    }
    
    /**
     * @dev Update the default interest rate (only owner)
     * @param newRate The new interest rate in basis points
     */
    function setDefaultInterestRate(uint256 newRate) external onlyOwner {
        require(newRate <= 10000, "Interest rate cannot exceed 100%");
        
        uint256 oldRate = defaultInterestRate;
        defaultInterestRate = newRate;
        
        emit InterestRateUpdated(oldRate, newRate);
    }
    
    /**
     * @dev Owner can deposit ETH to fund interest payments
     */
    function fundContract() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH");
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
