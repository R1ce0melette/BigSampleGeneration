// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    mapping(address => uint256) public totalDeposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit below minimum limit");
        totalDeposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(totalDeposits[msg.sender] >= amount, "Insufficient balance");
        totalDeposits[msg.sender] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Withdrawn(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return totalDeposits[msg.sender];
    }
}
