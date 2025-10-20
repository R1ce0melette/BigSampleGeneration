// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SavingsWallet
 * @dev A savings wallet contract where users can deposit and withdraw ETH
 */
contract SavingsWallet {
    // Minimum deposit amount in wei
    uint256 public constant MINIMUM_DEPOSIT = 0.001 ether;
    
    // Mapping to track total deposits per user
    mapping(address => uint256) public totalDeposits;
    
    // Mapping to track current balance per user
    mapping(address => uint256) public balances;
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 totalDeposited);
    event Withdrawal(address indexed user, uint256 amount, uint256 remainingBalance);
    
    /**
     * @dev Allows users to deposit ETH into their savings wallet
     * Requirements:
     * - Deposit amount must be at least MINIMUM_DEPOSIT
     */
    function deposit() external payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Deposit amount is below minimum limit");
        
        balances[msg.sender] += msg.value;
        totalDeposits[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value, totalDeposits[msg.sender]);
    }
    
    /**
     * @dev Allows users to withdraw ETH from their savings wallet
     * @param amount The amount of ETH to withdraw
     * Requirements:
     * - User must have sufficient balance
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        // Transfer ETH to user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }
    
    /**
     * @dev Returns the current balance of the caller
     * @return The balance of the caller
     */
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Returns the total deposits made by the caller
     * @return The total deposits of the caller
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits[msg.sender];
    }
    
    /**
     * @dev Returns the balance of a specific user
     * @param user The address of the user
     * @return The balance of the specified user
     */
    function getBalanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
    
    /**
     * @dev Returns the total deposits of a specific user
     * @param user The address of the user
     * @return The total deposits of the specified user
     */
    function getTotalDepositsOf(address user) external view returns (uint256) {
        return totalDeposits[user];
    }
}
