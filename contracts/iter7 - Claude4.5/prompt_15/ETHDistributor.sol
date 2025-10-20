// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ETHDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients
 */
contract ETHDistributor {
    address public owner;
    
    // Events
    event ETHDistributed(address[] recipients, uint256 amountPerRecipient, uint256 totalAmount, uint256 timestamp);
    event ETHSent(address indexed recipient, uint256 amount);
    event FundsReceived(address indexed sender, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    /**
     * @dev Constructor sets the contract owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Distribute ETH evenly among recipients
     * @param recipients Array of recipient addresses
     * Requirements:
     * - Only owner can call this function
     * - Recipients array must not be empty
     * - Contract must have sufficient balance
     * - Recipients must be unique and not zero address
     */
    function distributeETH(address[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "Recipients array cannot be empty");
        require(address(this).balance > 0, "Insufficient contract balance");
        
        uint256 amountPerRecipient = address(this).balance / recipients.length;
        require(amountPerRecipient > 0, "Amount per recipient is too small");
        
        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Recipient cannot be zero address");
            
            // Check for duplicates
            for (uint256 j = i + 1; j < recipients.length; j++) {
                require(recipients[i] != recipients[j], "Duplicate recipient addresses");
            }
        }
        
        // Distribute ETH
        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            totalDistributed += amountPerRecipient;
            emit ETHSent(recipients[i], amountPerRecipient);
        }
        
        emit ETHDistributed(recipients, amountPerRecipient, totalDistributed, block.timestamp);
    }
    
    /**
     * @dev Distribute a specific total amount evenly among recipients
     * @param recipients Array of recipient addresses
     * @param totalAmount Total amount to distribute
     * Requirements:
     * - Only owner can call this function
     * - Recipients array must not be empty
     * - Contract must have sufficient balance
     */
    function distributeAmount(address[] memory recipients, uint256 totalAmount) external onlyOwner {
        require(recipients.length > 0, "Recipients array cannot be empty");
        require(totalAmount > 0, "Total amount must be greater than 0");
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        uint256 amountPerRecipient = totalAmount / recipients.length;
        require(amountPerRecipient > 0, "Amount per recipient is too small");
        
        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Recipient cannot be zero address");
            
            // Check for duplicates
            for (uint256 j = i + 1; j < recipients.length; j++) {
                require(recipients[i] != recipients[j], "Duplicate recipient addresses");
            }
        }
        
        // Distribute ETH
        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            totalDistributed += amountPerRecipient;
            emit ETHSent(recipients[i], amountPerRecipient);
        }
        
        emit ETHDistributed(recipients, amountPerRecipient, totalDistributed, block.timestamp);
    }
    
    /**
     * @dev Distribute ETH with custom amounts for each recipient
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts corresponding to each recipient
     * Requirements:
     * - Only owner can call this function
     * - Arrays must have the same length
     * - Contract must have sufficient balance
     */
    function distributeCustomAmounts(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length > 0, "Recipients array cannot be empty");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        // Calculate total needed
        uint256 totalNeeded = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "Amount must be greater than 0");
            totalNeeded += amounts[i];
        }
        
        require(address(this).balance >= totalNeeded, "Insufficient contract balance");
        
        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Recipient cannot be zero address");
        }
        
        // Distribute ETH
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
            
            emit ETHSent(recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev Send ETH to a single recipient
     * @param recipient The recipient address
     * @param amount The amount to send
     */
    function sendETH(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit ETHSent(recipient, amount);
    }
    
    /**
     * @dev Calculate how much each recipient would receive
     * @param numberOfRecipients The number of recipients
     * @return The amount each recipient would receive
     */
    function calculateAmountPerRecipient(uint256 numberOfRecipients) external view returns (uint256) {
        require(numberOfRecipients > 0, "Number of recipients must be greater than 0");
        return address(this).balance / numberOfRecipients;
    }
    
    /**
     * @dev Calculate how much each recipient would receive from a specific amount
     * @param totalAmount The total amount to distribute
     * @param numberOfRecipients The number of recipients
     * @return The amount each recipient would receive
     */
    function calculateDistribution(uint256 totalAmount, uint256 numberOfRecipients) external pure returns (uint256) {
        require(numberOfRecipients > 0, "Number of recipients must be greater than 0");
        require(totalAmount > 0, "Total amount must be greater than 0");
        return totalAmount / numberOfRecipients;
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Withdraw all funds to owner
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Withdraw specific amount to owner
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Transfer ownership of the contract
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner is the same as current owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Receive ETH
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Fallback function to receive ETH
     */
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}
