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
    event Unlocked(address indexed user, uint256 amount, uint256 interest);

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }

    function lock(uint256 _lockDurationInDays) public payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        require(locks[msg.sender].amount == 0, "You already have a lock active.");
        require(_lockDurationInDays > 0, "Lock duration must be greater than zero.");

        uint256 unlockTime = block.timestamp + (_lockDurationInDays * 1 days);
        locks[msg.sender] = Lock(msg.value, unlockTime);

        emit Locked(msg.sender, msg.value, unlockTime);
    }

    function unlock() public {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "No active lock found.");
        require(block.timestamp >= userLock.unlockTime, "Lock period has not ended.");

        uint256 amount = userLock.amount;
        uint256 interest = (amount * interestRate) / 100;
        uint256 totalAmount = amount + interest;

        // Reset lock
        delete locks[msg.sender];

        payable(msg.sender).transfer(totalAmount);
        emit Unlocked(msg.sender, amount, interest);
    }

    function getLockDetails() public view returns (uint256, uint256) {
        Lock storage userLock = locks[msg.sender];
        return (userLock.amount, userLock.unlockTime);
    }
}
