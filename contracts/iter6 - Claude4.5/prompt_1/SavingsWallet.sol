// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SavingsWallet
 * @dev A savings wallet contract where users can deposit and withdraw ETH
 * with a minimum deposit limit and tracking of total deposits per user
 */
contract SavingsWallet {
    // Minimum deposit amount in wei
    uint256 public constant MINIMUM_DEPOSIT = 0.001 ether;
    
    // Mapping to track each user's balance
    mapping(address => uint256) public balances;
    
    // Mapping to track total deposits per user
    mapping(address => uint256) public totalDeposits;
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);
    
    /**
     * @dev Deposit ETH into the savings wallet
     * Requirements:
     * - Deposit amount must be at least MINIMUM_DEPOSIT
     */
    function deposit() external payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Deposit amount is below minimum");
        
        balances[msg.sender] += msg.value;
        totalDeposits[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }
    
    /**
     * @dev Withdraw ETH from the savings wallet
     * @param amount The amount to withdraw in wei
     * Requirements:
     * - User must have sufficient balance
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }
    
    /**
     * @dev Get the balance of a user
     * @param user The address of the user
     * @return The balance of the user
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    /**
     * @dev Get the total deposits of a user
     * @param user The address of the user
     * @return The total deposits of the user
     */
    function getTotalDeposits(address user) external view returns (uint256) {
        return totalDeposits[user];
    }
    
    /**
     * @dev Get the caller's balance
     * @return The balance of the caller
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Get the caller's total deposits
     * @return The total deposits of the caller
     */
    function getMyTotalDeposits() external view returns (uint256) {
        return totalDeposits[msg.sender];
    }
}
