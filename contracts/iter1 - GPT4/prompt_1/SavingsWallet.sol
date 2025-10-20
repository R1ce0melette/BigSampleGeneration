// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    address public owner;
    uint256 public minDeposit;
    mapping(address => uint256) public totalDeposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(uint256 _minDeposit) {
        owner = msg.sender;
        minDeposit = _minDeposit;
    }

    function deposit() external payable {
        require(msg.value >= minDeposit, "Deposit below minimum");
        totalDeposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(totalDeposits[msg.sender] >= amount, "Insufficient balance");
        totalDeposits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function getUserDeposit(address user) external view returns (uint256) {
        return totalDeposits[user];
    }

    function setMinDeposit(uint256 _minDeposit) external {
        require(msg.sender == owner, "Not owner");
        minDeposit = _minDeposit;
    }
}
