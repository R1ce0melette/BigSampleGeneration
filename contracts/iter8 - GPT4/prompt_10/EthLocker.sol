// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthLocker {
    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public interestRate; // e.g., 5 means 5%
    mapping(address => Deposit[]) public deposits;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount, uint256 interest);

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }

    function lockETH(uint256 lockPeriod) external payable {
        require(msg.value > 0, "No ETH sent");
        require(lockPeriod > 0, "Lock period required");
        uint256 unlockTime = block.timestamp + lockPeriod;
        deposits[msg.sender].push(Deposit(msg.value, unlockTime, false));
        emit Locked(msg.sender, msg.value, unlockTime);
    }

    function unlockETH(uint256 depositIndex) external {
        require(depositIndex < deposits[msg.sender].length, "Invalid index");
        Deposit storage dep = deposits[msg.sender][depositIndex];
        require(!dep.withdrawn, "Already withdrawn");
        require(block.timestamp >= dep.unlockTime, "Not unlocked yet");
        dep.withdrawn = true;
        uint256 interest = (dep.amount * interestRate) / 100;
        uint256 payout = dep.amount + interest;
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Transfer failed");
        emit Unlocked(msg.sender, dep.amount, interest);
    }

    function getDeposits(address user) external view returns (Deposit[] memory) {
        return deposits[user];
    }
}
