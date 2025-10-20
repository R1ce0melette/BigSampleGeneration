// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    // Minimum deposit amount in wei
    uint256 public constant MINIMUM_DEPOSIT = 0.01 ether;
    
    // Mapping to track total deposits per user
    mapping(address => uint256) public userDeposits;
    
    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    /**
     * @dev Deposit ETH into the savings wallet
     * @notice Requires a minimum deposit of 0.01 ETH
     */
    function deposit() external payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Deposit amount is below minimum");
        
        userDeposits[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw ETH from the savings wallet
     * @param amount The amount to withdraw in wei
     */
    function withdraw(uint256 amount) external {
        require(userDeposits[msg.sender] >= amount, "Insufficient balance");
        
        userDeposits[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @dev Get the total deposits for a specific user
     * @param user The address of the user
     * @return The total deposits for the user
     */
    function getUserDeposits(address user) external view returns (uint256) {
        return userDeposits[user];
    }
    
    /**
     * @dev Get the contract's total balance
     * @return The total balance held in the contract
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
