// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DepositWithFee {
    address public owner;
    uint256 public constant FEE_PERCENTAGE = 1; // 1% fee
    uint256 public totalFeesCollected;
    
    mapping(address => uint256) public balances;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        
        balances[msg.sender] += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Calculate fee (1%)
        uint256 fee = (_amount * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = _amount - fee;
        
        balances[msg.sender] -= _amount;
        totalFeesCollected += fee;
        
        (bool success, ) = payable(msg.sender).call{value: amountAfterFee}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }
    
    function withdrawAll() external {
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "No balance to withdraw");
        
        // Calculate fee (1%)
        uint256 fee = (userBalance * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = userBalance - fee;
        
        balances[msg.sender] = 0;
        totalFeesCollected += fee;
        
        (bool success, ) = payable(msg.sender).call{value: amountAfterFee}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }
    
    function withdrawFees() external onlyOwner {
        require(totalFeesCollected > 0, "No fees to withdraw");
        
        uint256 feesToWithdraw = totalFeesCollected;
        totalFeesCollected = 0;
        
        (bool success, ) = payable(owner).call{value: feesToWithdraw}("");
        require(success, "Transfer failed");
        
        emit FeesWithdrawn(owner, feesToWithdraw);
    }
    
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getUserBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    function calculateWithdrawalAmount(uint256 _amount) external pure returns (uint256 amountAfterFee, uint256 fee) {
        fee = (_amount * FEE_PERCENTAGE) / 100;
        amountAfterFee = _amount - fee;
        return (amountAfterFee, fee);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
