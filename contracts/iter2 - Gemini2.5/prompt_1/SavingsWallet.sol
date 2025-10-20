// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public minimumDeposit = 0.01 ether;
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public totalDeposits;

    function deposit() public payable {
        require(msg.value >= minimumDeposit, "Deposit amount is below the minimum limit.");
        userBalances[msg.sender] += msg.value;
        totalDeposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= userBalances[msg.sender], "Insufficient balance.");
        userBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return userBalances[msg.sender];
    }

    function getTotalDeposits() public view returns (uint256) {
        return totalDeposits[msg.sender];
    }
}
