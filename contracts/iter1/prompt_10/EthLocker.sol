// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthLocker {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    uint256 public interestRate = 5; // 5% fixed interest
    uint256 public lockPeriod = 30 days;
    mapping(address => Lock) public locks;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount, uint256 interest);

    function lockEth() external payable {
        require(msg.value > 0, "No ETH sent");
        require(locks[msg.sender].amount == 0 || locks[msg.sender].claimed, "Already locked");
        locks[msg.sender] = Lock(msg.value, block.timestamp + lockPeriod, false);
        emit Locked(msg.sender, msg.value, block.timestamp + lockPeriod);
    }

    function unlockEth() external {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "Nothing locked");
        require(!userLock.claimed, "Already claimed");
        require(block.timestamp >= userLock.unlockTime, "Lock period not over");
        uint256 interest = (userLock.amount * interestRate) / 100;
        uint256 payout = userLock.amount + interest;
        userLock.claimed = true;
        payable(msg.sender).transfer(payout);
        emit Unlocked(msg.sender, userLock.amount, interest);
    }

    function getLock(address user) external view returns (uint256 amount, uint256 unlockTime, bool claimed) {
        Lock storage l = locks[user];
        return (l.amount, l.unlockTime, l.claimed);
    }
}
