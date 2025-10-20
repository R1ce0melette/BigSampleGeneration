// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DepositWithdrawalFee
 * @dev A contract that allows users to deposit ETH and later withdraw with a 1% fee charged to the contract owner
 */
contract DepositWithdrawalFee {
    address public owner;
    uint256 public constant FEE_PERCENTAGE = 1; // 1% fee
    uint256 public totalFeesCollected;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public totalDeposited;
    mapping(address => uint256) public totalWithdrawn;
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 amount, uint256 fee, uint256 timestamp);
    event FeeCollected(address indexed owner, uint256 amount, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposited[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Withdraw ETH with a 1% fee
     * @param amount The amount to withdraw (before fee)
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Calculate fee (1%)
        uint256 fee = (amount * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = amount - fee;
        
        // Update balances
        balances[msg.sender] -= amount;
        totalWithdrawn[msg.sender] += amount;
        totalFeesCollected += fee;
        
        // Transfer amount to user
        (bool success, ) = payable(msg.sender).call{value: amountAfterFee}("");
        require(success, "Transfer to user failed");
        
        emit Withdrawal(msg.sender, amountAfterFee, fee, block.timestamp);
    }
    
    /**
     * @dev Withdraw all balance with a 1% fee
     */
    function withdrawAll() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        // Calculate fee (1%)
        uint256 fee = (amount * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = amount - fee;
        
        // Update balances
        balances[msg.sender] = 0;
        totalWithdrawn[msg.sender] += amount;
        totalFeesCollected += fee;
        
        // Transfer amount to user
        (bool success, ) = payable(msg.sender).call{value: amountAfterFee}("");
        require(success, "Transfer to user failed");
        
        emit Withdrawal(msg.sender, amountAfterFee, fee, block.timestamp);
    }
    
    /**
     * @dev Owner collects accumulated fees
     */
    function collectFees() external onlyOwner {
        uint256 feesToCollect = totalFeesCollected;
        require(feesToCollect > 0, "No fees to collect");
        
        totalFeesCollected = 0;
        
        (bool success, ) = payable(owner).call{value: feesToCollect}("");
        require(success, "Transfer to owner failed");
        
        emit FeeCollected(owner, feesToCollect, block.timestamp);
    }
    
    /**
     * @dev Get balance of a user
     * @param user The user address
     * @return The user's balance
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    /**
     * @dev Get caller's balance
     * @return The caller's balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Calculate withdrawal amount after fee
     * @param amount The amount to withdraw
     * @return amountAfterFee The amount after fee deduction
     * @return fee The fee amount
     */
    function calculateWithdrawal(uint256 amount) external pure returns (uint256 amountAfterFee, uint256 fee) {
        fee = (amount * FEE_PERCENTAGE) / 100;
        amountAfterFee = amount - fee;
        return (amountAfterFee, fee);
    }
    
    /**
     * @dev Get total deposited by a user
     * @param user The user address
     * @return Total deposited amount
     */
    function getTotalDeposited(address user) external view returns (uint256) {
        return totalDeposited[user];
    }
    
    /**
     * @dev Get total withdrawn by a user
     * @param user The user address
     * @return Total withdrawn amount
     */
    function getTotalWithdrawn(address user) external view returns (uint256) {
        return totalWithdrawn[user];
    }
    
    /**
     * @dev Get user statistics
     * @param user The user address
     * @return balance Current balance
     * @return deposited Total deposited
     * @return withdrawn Total withdrawn
     */
    function getUserStats(address user) external view returns (
        uint256 balance,
        uint256 deposited,
        uint256 withdrawn
    ) {
        return (
            balances[user],
            totalDeposited[user],
            totalWithdrawn[user]
        );
    }
    
    /**
     * @dev Get contract statistics
     * @return totalBalance Total ETH in contract
     * @return feesCollected Total fees collected
     */
    function getContractStats() external view returns (
        uint256 totalBalance,
        uint256 feesCollected
    ) {
        return (
            address(this).balance,
            totalFeesCollected
        );
    }
    
    /**
     * @dev Transfer ownership of the contract
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "Already the owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Get contract balance
     * @return Contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Receive function to accept ETH deposits
     */
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposited[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposited[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
}
