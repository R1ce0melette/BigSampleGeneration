// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    mapping(address => uint256) public userDeposits;
    uint256 public minimumDeposit;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(uint256 _minimumDeposit) {
        minimumDeposit = _minimumDeposit;
    }

    function deposit() public payable {
        require(msg.value >= minimumDeposit, "Deposit amount is below the minimum limit.");
        userDeposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public {
        require(userDeposits[msg.sender] >= _amount, "Insufficient balance.");
        userDeposits[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function getBalance() public view returns (uint256) {
        return userDeposits[msg.sender];
    }
}
