// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeVault {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public totalFees;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "No ETH sent");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        uint256 fee = amount / 100;
        uint256 payout = amount - fee;
        balances[msg.sender] -= amount;
        totalFees += fee;
        payable(msg.sender).transfer(payout);
    }

    function withdrawFees() external {
        require(msg.sender == owner, "Not owner");
        uint256 amount = totalFees;
        totalFees = 0;
        payable(owner).transfer(amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
