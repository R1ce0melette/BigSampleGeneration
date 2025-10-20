// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLock {
    struct Lock {
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 interestRate;
        bool withdrawn;
    }
    
    mapping(address => Lock[]) public userLocks;
    
    uint256 public constant INTEREST_RATE_30_DAYS = 5; // 5% for 30 days
    uint256 public constant INTEREST_RATE_90_DAYS = 15; // 15% for 90 days
    uint256 public constant INTEREST_RATE_180_DAYS = 35; // 35% for 180 days
    uint256 public constant INTEREST_RATE_365_DAYS = 75; // 75% for 365 days
    
    event ETHLocked(address indexed user, uint256 amount, uint256 lockDuration, uint256 unlockTime, uint256 interestRate);
    event ETHUnlocked(address indexed user, uint256 lockIndex, uint256 principal, uint256 interest, uint256 total);
    
    function lockETH(uint256 _lockDurationInDays) external payable {
        require(msg.value > 0, "Must lock some ETH");
        require(
            _lockDurationInDays == 30 || 
            _lockDurationInDays == 90 || 
            _lockDurationInDays == 180 || 
            _lockDurationInDays == 365,
            "Invalid lock duration. Must be 30, 90, 180, or 365 days"
        );
        
        uint256 interestRate = getInterestRate(_lockDurationInDays);
        uint256 unlockTime = block.timestamp + (_lockDurationInDays * 1 days);
        
        userLocks[msg.sender].push(Lock({
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            interestRate: interestRate,
            withdrawn: false
        }));
        
        emit ETHLocked(msg.sender, msg.value, _lockDurationInDays, unlockTime, interestRate);
    }
    
    function unlockETH(uint256 _lockIndex) external {
        require(_lockIndex < userLocks[msg.sender].length, "Invalid lock index");
        Lock storage lock = userLocks[msg.sender][_lockIndex];
        
        require(!lock.withdrawn, "Already withdrawn");
        require(block.timestamp >= lock.unlockTime, "Lock period not yet ended");
        
        uint256 principal = lock.amount;
        uint256 interest = (principal * lock.interestRate) / 100;
        uint256 total = principal + interest;
        
        lock.withdrawn = true;
        
        require(address(this).balance >= total, "Insufficient contract balance");
        
        (bool success, ) = msg.sender.call{value: total}("");
        require(success, "Transfer failed");
        
        emit ETHUnlocked(msg.sender, _lockIndex, principal, interest, total);
    }
    
    function getInterestRate(uint256 _lockDurationInDays) public pure returns (uint256) {
        if (_lockDurationInDays == 30) {
            return INTEREST_RATE_30_DAYS;
        } else if (_lockDurationInDays == 90) {
            return INTEREST_RATE_90_DAYS;
        } else if (_lockDurationInDays == 180) {
            return INTEREST_RATE_180_DAYS;
        } else if (_lockDurationInDays == 365) {
            return INTEREST_RATE_365_DAYS;
        }
        return 0;
    }
    
    function getUserLockCount(address _user) external view returns (uint256) {
        return userLocks[_user].length;
    }
    
    function getUserLock(address _user, uint256 _lockIndex) external view returns (
        uint256 amount,
        uint256 lockTime,
        uint256 unlockTime,
        uint256 interestRate,
        bool withdrawn,
        uint256 potentialInterest,
        uint256 potentialTotal
    ) {
        require(_lockIndex < userLocks[_user].length, "Invalid lock index");
        Lock memory lock = userLocks[_user][_lockIndex];
        
        uint256 interest = (lock.amount * lock.interestRate) / 100;
        uint256 total = lock.amount + interest;
        
        return (
            lock.amount,
            lock.lockTime,
            lock.unlockTime,
            lock.interestRate,
            lock.withdrawn,
            interest,
            total
        );
    }
    
    function getTimeUntilUnlock(address _user, uint256 _lockIndex) external view returns (uint256) {
        require(_lockIndex < userLocks[_user].length, "Invalid lock index");
        Lock memory lock = userLocks[_user][_lockIndex];
        
        if (block.timestamp >= lock.unlockTime) {
            return 0;
        }
        return lock.unlockTime - block.timestamp;
    }
    
    receive() external payable {}
}
