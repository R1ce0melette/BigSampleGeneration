// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthLocker {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    mapping(address => Lock) public locks;
    uint256 public interestRate; // e.g., 5 means 5%
    uint256 public lockPeriod; // in seconds

    constructor(uint256 _interestRate, uint256 _lockPeriod) {
        interestRate = _interestRate;
        lockPeriod = _lockPeriod;
    }

    function lock() external payable {
        require(msg.value > 0, "No ETH sent");
        require(locks[msg.sender].amount == 0 || locks[msg.sender].claimed, "Already locked");
        locks[msg.sender] = Lock(msg.value, block.timestamp + lockPeriod, false);
    }

    function unlock() external {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "Nothing locked");
        require(!userLock.claimed, "Already claimed");
        require(block.timestamp >= userLock.unlockTime, "Lock period not over");
        uint256 interest = (userLock.amount * interestRate) / 100;
        uint256 payout = userLock.amount + interest;
        userLock.claimed = true;
        payable(msg.sender).transfer(payout);
    }
}
