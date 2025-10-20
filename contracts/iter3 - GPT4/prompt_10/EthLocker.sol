// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthLocker {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    uint256 public interestRate; // e.g., 5 means 5%
    mapping(address => Lock) public locks;

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }

    function lockEth(uint256 lockPeriod) external payable {
        require(msg.value > 0, "No ETH sent");
        require(locks[msg.sender].amount == 0 || locks[msg.sender].claimed, "Already locked");
        locks[msg.sender] = Lock(msg.value, block.timestamp + lockPeriod, false);
    }

    function unlockEth() external {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "No ETH locked");
        require(!userLock.claimed, "Already claimed");
        require(block.timestamp >= userLock.unlockTime, "Lock period not over");
        uint256 interest = (userLock.amount * interestRate) / 100;
        uint256 payout = userLock.amount + interest;
        userLock.claimed = true;
        payable(msg.sender).transfer(payout);
    }

    function getLock(address user) external view returns (uint256, uint256, bool) {
        Lock storage l = locks[user];
        return (l.amount, l.unlockTime, l.claimed);
    }
}
