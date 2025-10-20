// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public constant MINIMUM_DEPOSIT = 0.01 ether;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public totalDeposits;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    function deposit() external payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Deposit amount below minimum");
        
        balances[msg.sender] += msg.value;
        totalDeposits[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits[msg.sender];
    }
}
