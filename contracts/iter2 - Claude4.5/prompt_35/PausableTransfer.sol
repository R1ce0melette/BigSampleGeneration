// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PausableTransfer {
    address public owner;
    bool public paused;
    
    mapping(address => uint256) public balances;
    
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public totalTransfers;
    
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event Transferred(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event Paused(address indexed by, uint256 timestamp);
    event Unpaused(address indexed by, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        paused = false;
    }
    
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    receive() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    function withdraw(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        totalWithdrawals += _amount;
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, _amount, block.timestamp);
    }
    
    function withdrawAll() external whenNotPaused {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        totalWithdrawals += balance;
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, balance, block.timestamp);
    }
    
    function transfer(address _to, uint256 _amount) external whenNotPaused {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_amount > 0, "Transfer amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        totalTransfers++;
        
        emit Transferred(msg.sender, _to, _amount, block.timestamp);
    }
    
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender, block.timestamp);
    }
    
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }
    
    function emergencyWithdraw() external onlyOwner whenPaused {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, balance, block.timestamp);
    }
    
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function isPaused() external view returns (bool) {
        return paused;
    }
    
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
    
    function getTotalWithdrawals() external view returns (uint256) {
        return totalWithdrawals;
    }
    
    function getTotalTransfers() external view returns (uint256) {
        return totalTransfers;
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner is the same as current owner");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
