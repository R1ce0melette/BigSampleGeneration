// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeLock
 * @dev Contract that allows users to lock ETH for a period and earn fixed interest when unlocked
 */
contract TimeLock {
    // Lock structure
    struct Lock {
        uint256 lockId;
        address user;
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 duration;
        uint256 interestRate;
        bool isUnlocked;
        bool exists;
    }

    // State variables
    address public owner;
    uint256 private lockIdCounter;
    uint256 public defaultInterestRate; // Interest rate in basis points (100 = 1%)
    
    mapping(uint256 => Lock) private locks;
    mapping(address => uint256[]) private userLocks;
    mapping(address => uint256) private totalLockedByUser;
    mapping(address => uint256) private totalEarnedByUser;

    // Events
    event ETHLocked(uint256 indexed lockId, address indexed user, uint256 amount, uint256 duration, uint256 unlockTime);
    event ETHUnlocked(uint256 indexed lockId, address indexed user, uint256 amount, uint256 interest);
    event InterestRateUpdated(uint256 oldRate, uint256 newRate);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier lockExists(uint256 lockId) {
        require(locks[lockId].exists, "Lock does not exist");
        _;
    }

    modifier onlyLockOwner(uint256 lockId) {
        require(locks[lockId].user == msg.sender, "Not the lock owner");
        _;
    }

    constructor(uint256 _defaultInterestRate) {
        owner = msg.sender;
        defaultInterestRate = _defaultInterestRate;
        lockIdCounter = 1;
    }

    /**
     * @dev Lock ETH for a specified duration
     * @param durationInDays Lock duration in days
     * @return lockId ID of the created lock
     */
    function lockETH(uint256 durationInDays) public payable returns (uint256) {
        require(msg.value > 0, "Must send ETH to lock");
        require(durationInDays > 0, "Duration must be greater than 0");

        uint256 lockId = lockIdCounter;
        lockIdCounter++;

        uint256 duration = durationInDays * 1 days;
        uint256 unlockTime = block.timestamp + duration;

        locks[lockId] = Lock({
            lockId: lockId,
            user: msg.sender,
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            duration: duration,
            interestRate: defaultInterestRate,
            isUnlocked: false,
            exists: true
        });

        userLocks[msg.sender].push(lockId);
        totalLockedByUser[msg.sender] += msg.value;

        emit ETHLocked(lockId, msg.sender, msg.value, duration, unlockTime);

        return lockId;
    }

    /**
     * @dev Lock ETH with custom interest rate (only owner can set custom rate)
     * @param durationInDays Lock duration in days
     * @param customInterestRate Custom interest rate in basis points
     * @return lockId ID of the created lock
     */
    function lockETHWithCustomRate(uint256 durationInDays, uint256 customInterestRate) 
        public 
        payable 
        onlyOwner 
        returns (uint256) 
    {
        require(msg.value > 0, "Must send ETH to lock");
        require(durationInDays > 0, "Duration must be greater than 0");

        uint256 lockId = lockIdCounter;
        lockIdCounter++;

        uint256 duration = durationInDays * 1 days;
        uint256 unlockTime = block.timestamp + duration;

        locks[lockId] = Lock({
            lockId: lockId,
            user: msg.sender,
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            duration: duration,
            interestRate: customInterestRate,
            isUnlocked: false,
            exists: true
        });

        userLocks[msg.sender].push(lockId);
        totalLockedByUser[msg.sender] += msg.value;

        emit ETHLocked(lockId, msg.sender, msg.value, duration, unlockTime);

        return lockId;
    }

    /**
     * @dev Unlock ETH and claim with interest
     * @param lockId Lock ID to unlock
     */
    function unlock(uint256 lockId) 
        public 
        lockExists(lockId) 
        onlyLockOwner(lockId) 
    {
        Lock storage lock = locks[lockId];
        require(!lock.isUnlocked, "Already unlocked");
        require(block.timestamp >= lock.unlockTime, "Lock period not completed");

        uint256 interest = calculateInterest(lockId);
        uint256 totalAmount = lock.amount + interest;

        require(address(this).balance >= totalAmount, "Insufficient contract balance");

        lock.isUnlocked = true;
        totalEarnedByUser[msg.sender] += interest;

        payable(msg.sender).transfer(totalAmount);

        emit ETHUnlocked(lockId, msg.sender, lock.amount, interest);
    }

    /**
     * @dev Calculate interest for a lock
     * @param lockId Lock ID
     * @return Interest amount
     */
    function calculateInterest(uint256 lockId) public view lockExists(lockId) returns (uint256) {
        Lock memory lock = locks[lockId];
        
        // Interest = (amount * interestRate * duration) / (10000 * 365 days)
        // This calculates proportional interest based on duration
        uint256 interest = (lock.amount * lock.interestRate * lock.duration) / (10000 * 365 days);
        
        return interest;
    }

    /**
     * @dev Set default interest rate
     * @param newRate New interest rate in basis points
     */
    function setDefaultInterestRate(uint256 newRate) public onlyOwner {
        require(newRate <= 10000, "Interest rate cannot exceed 100%");
        
        uint256 oldRate = defaultInterestRate;
        defaultInterestRate = newRate;

        emit InterestRateUpdated(oldRate, newRate);
    }

    /**
     * @dev Deposit funds to contract (for interest payments)
     */
    function depositFunds() public payable onlyOwner {
        require(msg.value > 0, "Must send ETH");
    }

    /**
     * @dev Get lock details
     * @param lockId Lock ID
     * @return Lock details
     */
    function getLock(uint256 lockId) public view lockExists(lockId) returns (Lock memory) {
        return locks[lockId];
    }

    /**
     * @dev Get locks for a user
     * @param user User address
     * @return Array of lock IDs
     */
    function getUserLocks(address user) public view returns (uint256[] memory) {
        return userLocks[user];
    }

    /**
     * @dev Get caller's locks
     * @return Array of lock IDs
     */
    function getMyLocks() public view returns (uint256[] memory) {
        return userLocks[msg.sender];
    }

    /**
     * @dev Get active locks for a user
     * @param user User address
     * @return Array of active lock IDs
     */
    function getActiveLocks(address user) public view returns (uint256[] memory) {
        uint256[] memory allLocks = userLocks[user];
        uint256 activeCount = 0;

        for (uint256 i = 0; i < allLocks.length; i++) {
            if (!locks[allLocks[i]].isUnlocked) {
                activeCount++;
            }
        }

        uint256[] memory activeLocks = new uint256[](activeCount);
        uint256 index = 0;

        for (uint256 i = 0; i < allLocks.length; i++) {
            if (!locks[allLocks[i]].isUnlocked) {
                activeLocks[index] = allLocks[i];
                index++;
            }
        }

        return activeLocks;
    }

    /**
     * @dev Check if a lock can be unlocked
     * @param lockId Lock ID
     * @return true if can be unlocked
     */
    function canUnlock(uint256 lockId) public view lockExists(lockId) returns (bool) {
        Lock memory lock = locks[lockId];
        return !lock.isUnlocked && block.timestamp >= lock.unlockTime;
    }

    /**
     * @dev Get time remaining until unlock
     * @param lockId Lock ID
     * @return Seconds remaining (0 if ready to unlock)
     */
    function getTimeRemaining(uint256 lockId) public view lockExists(lockId) returns (uint256) {
        Lock memory lock = locks[lockId];
        if (block.timestamp >= lock.unlockTime) {
            return 0;
        }
        return lock.unlockTime - block.timestamp;
    }

    /**
     * @dev Get total locked amount for a user
     * @param user User address
     * @return Total locked amount
     */
    function getTotalLocked(address user) public view returns (uint256) {
        uint256 total = 0;
        uint256[] memory allLocks = userLocks[user];

        for (uint256 i = 0; i < allLocks.length; i++) {
            if (!locks[allLocks[i]].isUnlocked) {
                total += locks[allLocks[i]].amount;
            }
        }

        return total;
    }

    /**
     * @dev Get total earned interest for a user
     * @param user User address
     * @return Total earned interest
     */
    function getTotalEarned(address user) public view returns (uint256) {
        return totalEarnedByUser[user];
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get total number of locks
     * @return Total lock count
     */
    function getTotalLocks() public view returns (uint256) {
        return lockIdCounter - 1;
    }

    /**
     * @dev Get potential earnings for a lock
     * @param lockId Lock ID
     * @return amount Principal amount
     * @return interest Interest amount
     * @return total Total amount (principal + interest)
     */
    function getPotentialEarnings(uint256 lockId) 
        public 
        view 
        lockExists(lockId) 
        returns (uint256 amount, uint256 interest, uint256 total) 
    {
        Lock memory lock = locks[lockId];
        interest = calculateInterest(lockId);
        return (lock.amount, interest, lock.amount + interest);
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return totalLocks Total number of locks
     * @return activeLocks Number of active locks
     * @return totalLockedAmount Total locked amount
     * @return totalEarned Total interest earned
     */
    function getUserStats(address user) 
        public 
        view 
        returns (
            uint256 totalLocks,
            uint256 activeLocks,
            uint256 totalLockedAmount,
            uint256 totalEarned
        ) 
    {
        uint256[] memory allLocks = userLocks[user];
        uint256 activeCount = 0;
        uint256 lockedAmount = 0;

        for (uint256 i = 0; i < allLocks.length; i++) {
            if (!locks[allLocks[i]].isUnlocked) {
                activeCount++;
                lockedAmount += locks[allLocks[i]].amount;
            }
        }

        return (allLocks.length, activeCount, lockedAmount, totalEarnedByUser[user]);
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
