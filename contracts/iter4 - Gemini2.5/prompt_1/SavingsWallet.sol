// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public minDeposit;
    mapping(address => uint256) public userDeposits;

    constructor(uint256 _minDeposit) {
        minDeposit = _minDeposit;
    }

    function deposit() public payable {
        require(msg.value >= minDeposit, "Deposit amount is below the minimum limit.");
        userDeposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public {
        require(userDeposits[msg.sender] >= _amount, "Withdrawal amount exceeds your balance.");
        userDeposits[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() public view returns (uint256) {
        return userDeposits[msg.sender];
    }
}
