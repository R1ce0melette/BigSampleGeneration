// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ETHDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients
 */
contract ETHDistributor {
    address public owner;
    
    // Events
    event FundsReceived(address indexed sender, uint256 amount);
    event DistributionCompleted(uint256 totalAmount, uint256 recipientCount, uint256 amountPerRecipient);
    event PaymentSent(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Distribute the contract's balance evenly among recipients
     * @param recipients Array of recipient addresses
     */
    function distribute(address[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(address(this).balance > 0, "No funds to distribute");
        
        uint256 totalAmount = address(this).balance;
        uint256 amountPerRecipient = totalAmount / recipients.length;
        
        require(amountPerRecipient > 0, "Insufficient balance for distribution");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            emit PaymentSent(recipients[i], amountPerRecipient);
        }
        
        emit DistributionCompleted(totalAmount, recipients.length, amountPerRecipient);
    }
    
    /**
     * @dev Distribute a specific amount evenly among recipients
     * @param recipients Array of recipient addresses
     * @param totalAmount Total amount to distribute
     */
    function distributeAmount(address[] memory recipients, uint256 totalAmount) external onlyOwner {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(totalAmount > 0, "Amount must be greater than 0");
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        uint256 amountPerRecipient = totalAmount / recipients.length;
        require(amountPerRecipient > 0, "Amount too small for distribution");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            emit PaymentSent(recipients[i], amountPerRecipient);
        }
        
        emit DistributionCompleted(totalAmount, recipients.length, amountPerRecipient);
    }
    
    /**
     * @dev Distribute custom amounts to recipients
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts (must match recipients length)
     */
    function distributeCustom(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(totalAmount > 0, "Total amount must be greater than 0");
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
            
            emit PaymentSent(recipients[i], amounts[i]);
        }
        
        emit DistributionCompleted(totalAmount, recipients.length, 0);
    }
    
    /**
     * @dev Calculate how much each recipient would receive from current balance
     * @param recipientCount Number of recipients
     * @return The amount each recipient would receive
     */
    function calculateDistribution(uint256 recipientCount) external view returns (uint256) {
        require(recipientCount > 0, "Recipient count must be greater than 0");
        return address(this).balance / recipientCount;
    }
    
    /**
     * @dev Calculate how much each recipient would receive from a specific amount
     * @param totalAmount The total amount to distribute
     * @param recipientCount Number of recipients
     * @return The amount each recipient would receive
     */
    function calculateDistributionFromAmount(uint256 totalAmount, uint256 recipientCount) external pure returns (uint256) {
        require(recipientCount > 0, "Recipient count must be greater than 0");
        require(totalAmount > 0, "Amount must be greater than 0");
        return totalAmount / recipientCount;
    }
    
    /**
     * @dev Get the contract balance
     * @return The contract's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Withdraw funds to owner (emergency function)
     * @param amount The amount to withdraw (0 to withdraw all)
     */
    function withdrawToOwner(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        uint256 withdrawAmount = amount == 0 ? balance : amount;
        require(withdrawAmount <= balance, "Insufficient balance");
        
        (bool success, ) = owner.call{value: withdrawAmount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Transfer ownership to a new address
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
     * @dev Deposit funds to the contract
     */
    function deposit() external payable {
        require(msg.value > 0, "Must send some ETH");
        emit FundsReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Receive function to accept ETH deposits
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}
