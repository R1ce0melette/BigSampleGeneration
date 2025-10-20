// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public minimumDeposit;
    mapping(address => uint256) public totalDeposits;
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event MinimumDepositUpdated(uint256 newMinimum);

    constructor(uint256 _minimumDeposit) {
        minimumDeposit = _minimumDeposit;
    }

    function deposit() external payable {
        require(msg.value >= minimumDeposit, "Deposit amount is below minimum");
        
        balances[msg.sender] += msg.value;
        totalDeposits[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit Withdrawal(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getTotalDeposits(address user) external view returns (uint256) {
        return totalDeposits[user];
    }

    function updateMinimumDeposit(uint256 _newMinimum) external {
        minimumDeposit = _newMinimum;
        emit MinimumDepositUpdated(_newMinimum);
    }
}
