// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeVault {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public totalFees;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "No ETH sent");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        uint256 fee = amount / 100;
        uint256 payout = amount - fee;
        balances[msg.sender] -= amount;
        totalFees += fee;
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Withdraw failed");
        emit Withdrawn(msg.sender, payout, fee);
    }

    function withdrawFees() external {
        require(msg.sender == owner, "Not owner");
        require(totalFees > 0, "No fees");
        uint256 amount = totalFees;
        totalFees = 0;
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Fee withdraw failed");
        emit FeesWithdrawn(owner, amount);
    }
}
