// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLockedWallet {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;
    uint256 public interestRate; // e.g., 5 for 5%

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount);

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }

    function lock(uint256 _lockDurationInSeconds) public payable {
        require(msg.value > 0, "Must lock a positive amount.");
        require(locks[msg.sender].amount == 0, "You already have a lock.");

        locks[msg.sender] = Lock({
            amount: msg.value,
            unlockTime: block.timestamp + _lockDurationInSeconds
        });

        emit Locked(msg.sender, msg.value, locks[msg.sender].unlockTime);
    }

    function unlock() public {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "You have no locked funds.");
        require(block.timestamp >= userLock.unlockTime, "Lock period has not ended.");

        uint256 interest = (userLock.amount * interestRate) / 100;
        uint256 totalAmount = userLock.amount + interest;
        
        delete locks[msg.sender];

        payable(msg.sender).transfer(totalAmount);

        emit Unlocked(msg.sender, totalAmount);
    }
}
