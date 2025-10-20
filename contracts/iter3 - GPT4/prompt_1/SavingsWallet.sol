// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public minDeposit;
    mapping(address => uint256) public totalDeposits;

    constructor(uint256 _minDeposit) {
        minDeposit = _minDeposit;
    }

    function deposit() external payable {
        require(msg.value >= minDeposit, "Deposit below minimum limit");
        totalDeposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(totalDeposits[msg.sender] >= amount, "Insufficient balance");
        totalDeposits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance() external view returns (uint256) {
        return totalDeposits[msg.sender];
    }
}
