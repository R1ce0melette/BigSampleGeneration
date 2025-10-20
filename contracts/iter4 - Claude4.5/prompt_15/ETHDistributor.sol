// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ETHDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients
 */
contract ETHDistributor {
    address public owner;
    
    // Events
    event ETHReceived(address indexed sender, uint256 amount);
    event ETHDistributed(address[] recipients, uint256 amountPerRecipient, uint256 totalDistributed);
    event SingleDistribution(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Distributes ETH evenly among a list of recipients
     * @param _recipients Array of recipient addresses
     */
    function distributeEvenly(address[] memory _recipients) external onlyOwner {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        require(address(this).balance > 0, "No ETH to distribute");
        
        uint256 amountPerRecipient = address(this).balance / _recipients.length;
        require(amountPerRecipient > 0, "Insufficient balance to distribute");
        
        uint256 totalDistributed = 0;
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            totalDistributed += amountPerRecipient;
            emit SingleDistribution(_recipients[i], amountPerRecipient);
        }
        
        emit ETHDistributed(_recipients, amountPerRecipient, totalDistributed);
    }
    
    /**
     * @dev Distributes a specific total amount evenly among recipients
     * @param _recipients Array of recipient addresses
     * @param _totalAmount The total amount to distribute
     */
    function distributeAmount(address[] memory _recipients, uint256 _totalAmount) external onlyOwner {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        require(_totalAmount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _totalAmount, "Insufficient contract balance");
        
        uint256 amountPerRecipient = _totalAmount / _recipients.length;
        require(amountPerRecipient > 0, "Amount too small to distribute");
        
        uint256 totalDistributed = 0;
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            totalDistributed += amountPerRecipient;
            emit SingleDistribution(_recipients[i], amountPerRecipient);
        }
        
        emit ETHDistributed(_recipients, amountPerRecipient, totalDistributed);
    }
    
    /**
     * @dev Distributes specific amounts to each recipient
     * @param _recipients Array of recipient addresses
     * @param _amounts Array of amounts corresponding to each recipient
     */
    function distributeCustomAmounts(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        
        uint256 totalRequired = 0;
        
        // Calculate total required amount
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0, "Amount must be greater than 0");
            totalRequired += _amounts[i];
        }
        
        require(address(this).balance >= totalRequired, "Insufficient contract balance");
        
        // Distribute to each recipient
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: _amounts[i]}("");
            require(success, "Transfer failed");
            
            emit SingleDistribution(_recipients[i], _amounts[i]);
        }
        
        emit ETHDistributed(_recipients, 0, totalRequired);
    }
    
    /**
     * @dev Calculates how much each recipient would receive for even distribution
     * @param _recipients Array of recipient addresses
     * @return The amount each recipient would receive
     */
    function calculateEvenDistribution(address[] memory _recipients) external view returns (uint256) {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        
        return address(this).balance / _recipients.length;
    }
    
    /**
     * @dev Calculates how much each recipient would receive from a specific amount
     * @param _recipients Array of recipient addresses
     * @param _totalAmount The total amount to distribute
     * @return The amount each recipient would receive
     */
    function calculateDistributionFromAmount(address[] memory _recipients, uint256 _totalAmount) 
        external 
        pure 
        returns (uint256) 
    {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        require(_totalAmount > 0, "Amount must be greater than 0");
        
        return _totalAmount / _recipients.length;
    }
    
    /**
     * @dev Allows the owner to withdraw a specific amount
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Allows the owner to withdraw all ETH
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Returns the contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Fallback function to receive ETH
     */
    fallback() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
}
