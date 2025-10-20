// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EvenDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients
 */
contract EvenDistributor {
    address public owner;
    
    event FundsReceived(address indexed from, uint256 amount);
    event FundsDistributed(address[] recipients, uint256 amountPerRecipient, uint256 totalDistributed);
    event SingleDistribution(address indexed recipient, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Distribute contract balance evenly among recipients
     * @param recipients Array of recipient addresses
     */
    function distribute(address payable[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(address(this).balance > 0, "No funds to distribute");
        
        uint256 totalBalance = address(this).balance;
        uint256 amountPerRecipient = totalBalance / recipients.length;
        
        require(amountPerRecipient > 0, "Insufficient funds for distribution");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            emit SingleDistribution(recipients[i], amountPerRecipient);
        }
        
        emit FundsDistributed(recipients, amountPerRecipient, amountPerRecipient * recipients.length);
    }
    
    /**
     * @dev Distribute a specific amount evenly among recipients
     * @param recipients Array of recipient addresses
     * @param totalAmount Total amount to distribute
     */
    function distributeAmount(address payable[] memory recipients, uint256 totalAmount) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(totalAmount > 0, "Amount must be greater than 0");
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        uint256 amountPerRecipient = totalAmount / recipients.length;
        require(amountPerRecipient > 0, "Insufficient amount for distribution");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            emit SingleDistribution(recipients[i], amountPerRecipient);
        }
        
        emit FundsDistributed(recipients, amountPerRecipient, amountPerRecipient * recipients.length);
    }
    
    /**
     * @dev Distribute specific amounts to each recipient
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts corresponding to each recipient
     */
    function distributeCustomAmounts(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        uint256 totalRequired = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalRequired += amounts[i];
        }
        
        require(address(this).balance >= totalRequired, "Insufficient contract balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
            
            emit SingleDistribution(recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev Deposit funds into the contract
     */
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        emit FundsReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw all funds to owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Withdraw specific amount to owner
     * @param amount The amount to withdraw
     */
    function withdrawAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Get the contract balance
     * @return The current balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Calculate how much each recipient would receive
     * @param recipientCount Number of recipients
     * @return Amount per recipient
     */
    function calculateDistribution(uint256 recipientCount) external view returns (uint256) {
        require(recipientCount > 0, "Recipient count must be greater than 0");
        return address(this).balance / recipientCount;
    }
    
    /**
     * @dev Calculate distribution for a specific total amount
     * @param recipientCount Number of recipients
     * @param totalAmount Total amount to distribute
     * @return Amount per recipient
     */
    function calculateDistributionForAmount(
        uint256 recipientCount,
        uint256 totalAmount
    ) external pure returns (uint256) {
        require(recipientCount > 0, "Recipient count must be greater than 0");
        require(totalAmount > 0, "Total amount must be greater than 0");
        return totalAmount / recipientCount;
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Fallback function to accept ETH
     */
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}
