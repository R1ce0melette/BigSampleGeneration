// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EvenDistribution {
    address public owner;
    
    event FundsDistributed(address[] recipients, uint256 amountPerRecipient, uint256 totalDistributed);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function distribute(address payable[] calldata _recipients) external onlyOwner {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        require(address(this).balance > 0, "Contract has no balance to distribute");
        
        uint256 balance = address(this).balance;
        uint256 amountPerRecipient = balance / _recipients.length;
        
        require(amountPerRecipient > 0, "Insufficient balance for distribution");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Recipient cannot be zero address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
        }
        
        emit FundsDistributed(_recipients, amountPerRecipient, amountPerRecipient * _recipients.length);
    }
    
    function distributeAmount(address payable[] calldata _recipients, uint256 _totalAmount) external onlyOwner {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        require(_totalAmount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _totalAmount, "Insufficient contract balance");
        
        uint256 amountPerRecipient = _totalAmount / _recipients.length;
        require(amountPerRecipient > 0, "Insufficient amount for distribution");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Recipient cannot be zero address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
        }
        
        emit FundsDistributed(_recipients, amountPerRecipient, amountPerRecipient * _recipients.length);
    }
    
    function distributeWithAmounts(address payable[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length > 0, "Recipients list cannot be empty");
        require(_recipients.length == _amounts.length, "Recipients and amounts length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Recipient cannot be zero address");
            require(_amounts[i] > 0, "Amount must be greater than 0");
            
            (bool success, ) = _recipients[i].call{value: _amounts[i]}("");
            require(success, "Transfer failed");
        }
    }
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function calculateDistribution(uint256 _totalAmount, uint256 _recipientCount) external pure returns (uint256 amountPerRecipient, uint256 remainder) {
        require(_recipientCount > 0, "Recipient count must be greater than 0");
        
        amountPerRecipient = _totalAmount / _recipientCount;
        remainder = _totalAmount % _recipientCount;
        
        return (amountPerRecipient, remainder);
    }
    
    function withdrawRemaining() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner is the same as current owner");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
