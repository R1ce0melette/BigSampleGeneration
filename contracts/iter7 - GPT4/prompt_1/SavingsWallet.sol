// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public totalDeposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit below minimum limit");
        balances[msg.sender] += msg.value;
        totalDeposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getTotalDeposits(address user) external view returns (uint256) {
        return totalDeposits[user];
    }
}
