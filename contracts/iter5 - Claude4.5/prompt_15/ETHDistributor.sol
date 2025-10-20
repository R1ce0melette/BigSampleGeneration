// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthDistributor {
    address public owner;
    
    event FundsDistributed(address[] recipients, uint256 amountPerRecipient, uint256 totalAmount);
    event SingleTransfer(address indexed recipient, uint256 amount);
    event FundsReceived(address indexed sender, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function distributeEvenly(address payable[] memory _recipients) external onlyOwner {
        require(_recipients.length > 0, "No recipients provided");
        require(address(this).balance > 0, "No funds to distribute");
        
        uint256 amountPerRecipient = address(this).balance / _recipients.length;
        require(amountPerRecipient > 0, "Insufficient funds for distribution");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            emit SingleTransfer(_recipients[i], amountPerRecipient);
        }
        
        emit FundsDistributed(_recipients, amountPerRecipient, amountPerRecipient * _recipients.length);
    }
    
    function distributeSpecificAmount(address payable[] memory _recipients, uint256 _totalAmount) external onlyOwner {
        require(_recipients.length > 0, "No recipients provided");
        require(_totalAmount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _totalAmount, "Insufficient contract balance");
        
        uint256 amountPerRecipient = _totalAmount / _recipients.length;
        require(amountPerRecipient > 0, "Amount per recipient is zero");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            emit SingleTransfer(_recipients[i], amountPerRecipient);
        }
        
        emit FundsDistributed(_recipients, amountPerRecipient, amountPerRecipient * _recipients.length);
    }
    
    function distributeCustomAmounts(address payable[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length > 0, "No recipients provided");
        require(_recipients.length == _amounts.length, "Recipients and amounts length mismatch");
        
        uint256 totalRequired = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalRequired += _amounts[i];
        }
        
        require(address(this).balance >= totalRequired, "Insufficient contract balance");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            require(_amounts[i] > 0, "Amount must be greater than zero");
            
            (bool success, ) = _recipients[i].call{value: _amounts[i]}("");
            require(success, "Transfer failed");
            
            emit SingleTransfer(_recipients[i], _amounts[i]);
        }
        
        emit FundsDistributed(_recipients, 0, totalRequired);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
    
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}
