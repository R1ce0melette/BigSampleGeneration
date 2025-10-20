// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DepositWithdrawFee {
    address public owner;
    uint256 public feePercentage = 1; // 1% fee
    uint256 public constant MAX_FEE = 10; // Maximum 10% fee
    
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    uint256 public totalFeeCollected;
    
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee, uint256 timestamp);
    event FeeCollected(address indexed owner, uint256 amount);
    event FeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Calculate fee
        uint256 fee = (_amount * feePercentage) / 100;
        uint256 amountAfterFee = _amount - fee;
        
        balances[msg.sender] -= _amount;
        totalFeeCollected += fee;
        
        // Transfer amount after fee to user
        (bool success, ) = msg.sender.call{value: amountAfterFee}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amountAfterFee, fee, block.timestamp);
    }
    
    function withdrawAll() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        
        // Calculate fee
        uint256 fee = (balance * feePercentage) / 100;
        uint256 amountAfterFee = balance - fee;
        
        balances[msg.sender] = 0;
        totalFeeCollected += fee;
        
        // Transfer amount after fee to user
        (bool success, ) = msg.sender.call{value: amountAfterFee}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amountAfterFee, fee, block.timestamp);
    }
    
    function collectFees() external onlyOwner {
        require(totalFeeCollected > 0, "No fees to collect");
        
        uint256 fees = totalFeeCollected;
        totalFeeCollected = 0;
        
        (bool success, ) = owner.call{value: fees}("");
        require(success, "Transfer failed");
        
        emit FeeCollected(owner, fees);
    }
    
    function updateFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= MAX_FEE, "Fee percentage exceeds maximum");
        
        uint256 oldPercentage = feePercentage;
        feePercentage = _newPercentage;
        
        emit FeePercentageUpdated(oldPercentage, _newPercentage);
    }
    
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    function calculateWithdrawalAmount(uint256 _amount) external view returns (uint256 fee, uint256 amountAfterFee) {
        fee = (_amount * feePercentage) / 100;
        amountAfterFee = _amount - fee;
        return (fee, amountAfterFee);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
    
    function getTotalFeeCollected() external view returns (uint256) {
        return totalFeeCollected;
    }
    
    function getFeePercentage() external view returns (uint256) {
        return feePercentage;
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner is the same as current owner");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
    
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
