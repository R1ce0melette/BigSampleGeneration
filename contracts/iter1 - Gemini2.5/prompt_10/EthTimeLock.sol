// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthTimeLock {

    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        uint256 lockTime;
    }

    mapping(address => Lock) public locks;
    uint256 public constant INTEREST_RATE_PER_YEAR_PERCENT = 5; // 5% annual interest

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount, uint256 interest);

    function lockEth(uint256 lockDurationSeconds) public payable {
        require(msg.value > 0, "Must lock some ETH");
        require(locks[msg.sender].amount == 0, "You already have an active lock.");

        uint256 unlockTime = block.timestamp + lockDurationSeconds;
        locks[msg.sender] = Lock({
            amount: msg.value,
            unlockTime: unlockTime,
            lockTime: block.timestamp
        });

        emit Locked(msg.sender, msg.value, unlockTime);
    }

    function withdraw() public {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "No ETH locked.");
        require(block.timestamp >= userLock.unlockTime, "Lock period not over yet.");

        uint256 principal = userLock.amount;
        uint256 lockDuration = userLock.unlockTime - userLock.lockTime;

        // Calculate interest: (principal * rate * duration) / (100 * 1 year)
        uint256 interest = (principal * INTEREST_RATE_PER_YEAR_PERCENT * lockDuration) / (100 * 365 days);

        // Reset lock
        delete locks[msg.sender];

        emit Withdrawn(msg.sender, principal, interest);

        payable(msg.sender).transfer(principal + interest);
    }

    function getLockDetails(address user) public view returns (uint256 amount, uint256 unlockTime, uint256 lockTime) {
        Lock storage userLock = locks[user];
        return (userLock.amount, userLock.unlockTime, userLock.lockTime);
    }
}
