// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public minDeposit = 0.01 ether;
    mapping(address => uint256) public userDeposits;

    function deposit() public payable {
        require(msg.value >= minDeposit, "Deposit amount is too low");
        userDeposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(userDeposits[msg.sender] >= amount, "Insufficient balance");
        userDeposits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return userDeposits[msg.sender];
    }
}
