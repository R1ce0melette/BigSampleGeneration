// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthDistributor {
    address public owner;
    
    // Events
    event FundsReceived(address indexed from, uint256 amount);
    event FundsDistributed(address[] recipients, uint256 amountPerRecipient, uint256 totalDistributed);
    event SingleTransfer(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Receive ETH
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Distribute ETH evenly among recipients
     * @param _recipients Array of recipient addresses
     */
    function distributeEvenly(address payable[] memory _recipients) external onlyOwner {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        require(address(this).balance > 0, "No funds to distribute");
        
        uint256 amountPerRecipient = address(this).balance / _recipients.length;
        require(amountPerRecipient > 0, "Insufficient balance for distribution");
        
        uint256 totalDistributed = 0;
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            totalDistributed += amountPerRecipient;
        }
        
        emit FundsDistributed(_recipients, amountPerRecipient, totalDistributed);
    }
    
    /**
     * @dev Distribute a specific amount evenly among recipients
     * @param _recipients Array of recipient addresses
     * @param _totalAmount Total amount to distribute
     */
    function distributeAmount(address payable[] memory _recipients, uint256 _totalAmount) external onlyOwner {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        require(_totalAmount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _totalAmount, "Insufficient contract balance");
        
        uint256 amountPerRecipient = _totalAmount / _recipients.length;
        require(amountPerRecipient > 0, "Amount too small for distribution");
        
        uint256 totalDistributed = 0;
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            totalDistributed += amountPerRecipient;
        }
        
        emit FundsDistributed(_recipients, amountPerRecipient, totalDistributed);
    }
    
    /**
     * @dev Distribute custom amounts to recipients
     * @param _recipients Array of recipient addresses
     * @param _amounts Array of amounts corresponding to each recipient
     */
    function distributeCustomAmounts(
        address payable[] memory _recipients,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        
        uint256 totalAmount = 0;
        
        // Calculate total amount needed
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0, "Amount must be greater than 0");
            totalAmount += _amounts[i];
        }
        
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        // Distribute funds
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: _amounts[i]}("");
            require(success, "Transfer failed");
            
            emit SingleTransfer(_recipients[i], _amounts[i]);
        }
    }
    
    /**
     * @dev Send ETH to a single recipient
     * @param _recipient The recipient address
     * @param _amount The amount to send
     */
    function sendToRecipient(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit SingleTransfer(_recipient, _amount);
    }
    
    /**
     * @dev Withdraw all funds to owner
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit SingleTransfer(owner, balance);
    }
    
    /**
     * @dev Withdraw specific amount to owner
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit SingleTransfer(owner, _amount);
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Calculate amount per recipient for even distribution
     * @param _recipients Array of recipient addresses
     * @return The amount each recipient would receive
     */
    function calculateAmountPerRecipient(address[] memory _recipients) external view returns (uint256) {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        
        return address(this).balance / _recipients.length;
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
