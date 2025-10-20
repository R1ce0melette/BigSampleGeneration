// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthLocker {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    uint256 public constant INTEREST_RATE = 5; // 5% fixed interest
    uint256 public constant YEAR = 365 days;
    mapping(address => Lock) public locks;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount, uint256 interest);

    function lock(uint256 period) external payable {
        require(msg.value > 0, "No ETH sent");
        require(locks[msg.sender].amount == 0 || locks[msg.sender].claimed, "Already locked");
        require(period > 0, "Period must be positive");
        locks[msg.sender] = Lock({
            amount: msg.value,
            unlockTime: block.timestamp + period,
            claimed: false
        });
        emit Locked(msg.sender, msg.value, block.timestamp + period);
    }

    function unlock() external {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "Nothing locked");
        require(!userLock.claimed, "Already claimed");
        require(block.timestamp >= userLock.unlockTime, "Lock period not ended");
        uint256 interest = (userLock.amount * INTEREST_RATE * (userLock.unlockTime - (userLock.unlockTime - YEAR))) / (100 * YEAR);
        uint256 payout = userLock.amount + interest;
        userLock.claimed = true;
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Transfer failed");
        emit Unlocked(msg.sender, userLock.amount, interest);
    }

    function getLock(address user) external view returns (uint256 amount, uint256 unlockTime, bool claimed) {
        Lock storage l = locks[user];
        return (l.amount, l.unlockTime, l.claimed);
    }
}
