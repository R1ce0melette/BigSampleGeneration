// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StakingLock
 * @dev A contract that allows users to lock their ETH for a period and earn fixed interest when unlocked
 */
contract StakingLock {
    struct Lock {
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 interestRate; // Interest rate in basis points (e.g., 500 = 5%)
        bool withdrawn;
    }
    
    // Mapping from user address to their locks
    mapping(address => Lock[]) public userLocks;
    
    // Interest rates based on lock duration (in days => basis points)
    mapping(uint256 => uint256) public interestRates;
    
    address public owner;
    
    // Events
    event ETHLocked(address indexed user, uint256 amount, uint256 lockDuration, uint256 unlockTime, uint256 interestRate);
    event ETHUnlocked(address indexed user, uint256 lockIndex, uint256 principal, uint256 interest);
    event InterestRateSet(uint256 duration, uint256 rate);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        // Set default interest rates (basis points: 100 = 1%)
        interestRates[30] = 300;   // 30 days = 3%
        interestRates[90] = 800;   // 90 days = 8%
        interestRates[180] = 1500; // 180 days = 15%
        interestRates[365] = 2500; // 365 days = 25%
    }
    
    /**
     * @dev Allows users to lock ETH for a specified duration
     * @param _lockDuration The duration to lock ETH in days
     */
    function lockETH(uint256 _lockDuration) external payable {
        require(msg.value > 0, "Must send ETH to lock");
        require(interestRates[_lockDuration] > 0, "Invalid lock duration");
        
        uint256 unlockTime = block.timestamp + (_lockDuration * 1 days);
        uint256 rate = interestRates[_lockDuration];
        
        userLocks[msg.sender].push(Lock({
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            interestRate: rate,
            withdrawn: false
        }));
        
        emit ETHLocked(msg.sender, msg.value, _lockDuration, unlockTime, rate);
    }
    
    /**
     * @dev Allows users to unlock and withdraw their ETH with interest
     * @param _lockIndex The index of the lock to withdraw
     */
    function unlockETH(uint256 _lockIndex) external {
        require(_lockIndex < userLocks[msg.sender].length, "Invalid lock index");
        
        Lock storage lock = userLocks[msg.sender][_lockIndex];
        
        require(!lock.withdrawn, "Already withdrawn");
        require(block.timestamp >= lock.unlockTime, "Lock period not completed");
        
        lock.withdrawn = true;
        
        // Calculate interest: principal * rate / 10000
        uint256 interest = (lock.amount * lock.interestRate) / 10000;
        uint256 totalAmount = lock.amount + interest;
        
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed");
        
        emit ETHUnlocked(msg.sender, _lockIndex, lock.amount, interest);
    }
    
    /**
     * @dev Allows the owner to set or update interest rates for specific durations
     * @param _duration The lock duration in days
     * @param _rate The interest rate in basis points (e.g., 500 = 5%)
     */
    function setInterestRate(uint256 _duration, uint256 _rate) external onlyOwner {
        require(_duration > 0, "Duration must be greater than 0");
        require(_rate > 0, "Rate must be greater than 0");
        require(_rate <= 10000, "Rate cannot exceed 100%");
        
        interestRates[_duration] = _rate;
        
        emit InterestRateSet(_duration, _rate);
    }
    
    /**
     * @dev Allows the owner to fund the contract for interest payments
     */
    function fundContract() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH");
    }
    
    /**
     * @dev Returns the number of locks for a user
     * @param _user The address of the user
     * @return The number of locks
     */
    function getUserLockCount(address _user) external view returns (uint256) {
        return userLocks[_user].length;
    }
    
    /**
     * @dev Returns details of a specific lock
     * @param _user The address of the user
     * @param _lockIndex The index of the lock
     * @return amount The locked amount
     * @return lockTime When the ETH was locked
     * @return unlockTime When the ETH can be unlocked
     * @return interestRate The interest rate in basis points
     * @return withdrawn Whether the lock has been withdrawn
     */
    function getLockDetails(address _user, uint256 _lockIndex) external view returns (
        uint256 amount,
        uint256 lockTime,
        uint256 unlockTime,
        uint256 interestRate,
        bool withdrawn
    ) {
        require(_lockIndex < userLocks[_user].length, "Invalid lock index");
        
        Lock memory lock = userLocks[_user][_lockIndex];
        
        return (
            lock.amount,
            lock.lockTime,
            lock.unlockTime,
            lock.interestRate,
            lock.withdrawn
        );
    }
    
    /**
     * @dev Calculates the potential interest for a lock
     * @param _user The address of the user
     * @param _lockIndex The index of the lock
     * @return The interest amount
     */
    function calculateInterest(address _user, uint256 _lockIndex) external view returns (uint256) {
        require(_lockIndex < userLocks[_user].length, "Invalid lock index");
        
        Lock memory lock = userLocks[_user][_lockIndex];
        
        return (lock.amount * lock.interestRate) / 10000;
    }
    
    /**
     * @dev Returns all active (not withdrawn) locks for a user
     * @param _user The address of the user
     * @return Array of lock indices that are active
     */
    function getActiveLocks(address _user) external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active locks
        for (uint256 i = 0; i < userLocks[_user].length; i++) {
            if (!userLocks[_user][i].withdrawn) {
                activeCount++;
            }
        }
        
        // Create array of active lock indices
        uint256[] memory activeLocks = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userLocks[_user].length; i++) {
            if (!userLocks[_user][i].withdrawn) {
                activeLocks[index] = i;
                index++;
            }
        }
        
        return activeLocks;
    }
    
    /**
     * @dev Returns the time remaining until a lock can be unlocked
     * @param _user The address of the user
     * @param _lockIndex The index of the lock
     * @return Time remaining in seconds, or 0 if already unlockable
     */
    function getTimeUntilUnlock(address _user, uint256 _lockIndex) external view returns (uint256) {
        require(_lockIndex < userLocks[_user].length, "Invalid lock index");
        
        Lock memory lock = userLocks[_user][_lockIndex];
        
        if (block.timestamp >= lock.unlockTime) {
            return 0;
        }
        
        return lock.unlockTime - block.timestamp;
    }
    
    /**
     * @dev Returns the contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
