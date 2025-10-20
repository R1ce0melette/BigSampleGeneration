// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeVault {
    address public owner;
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);

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
        payable(msg.sender).transfer(payout);
        payable(owner).transfer(fee);
        emit Withdrawn(msg.sender, payout, fee);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
