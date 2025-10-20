// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DepositWithdrawalFee
 * @dev A contract that allows users to deposit ETH and later withdraw with a 1% fee charged to the contract owner
 */
contract DepositWithdrawalFee {
    struct UserAccount {
        uint256 balance;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 depositCount;
        uint256 withdrawalCount;
        uint256 lastDepositTime;
        uint256 lastWithdrawalTime;
    }
    
    struct Transaction {
        address user;
        uint256 amount;
        uint256 timestamp;
        bool isDeposit;
    }
    
    address public owner;
    uint256 public feePercentage;
    uint256 public constant FEE_DENOMINATOR = 100;
    uint256 public totalFeesCollected;
    
    mapping(address => UserAccount) public userAccounts;
    Transaction[] private transactionHistory;
    mapping(address => Transaction[]) private userTransactions;
    
    address[] private depositors;
    mapping(address => bool) private isDepositor;
    
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(
        address indexed user,
        uint256 amount,
        uint256 fee,
        uint256 netAmount,
        uint256 timestamp
    );
    event FeeCollected(address indexed owner, uint256 amount);
    event OwnerWithdrawal(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        feePercentage = 1; // 1% fee
    }
    
    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        UserAccount storage account = userAccounts[msg.sender];
        
        account.balance += msg.value;
        account.totalDeposited += msg.value;
        account.depositCount++;
        account.lastDepositTime = block.timestamp;
        
        // Track new depositor
        if (!isDepositor[msg.sender]) {
            depositors.push(msg.sender);
            isDepositor[msg.sender] = true;
        }
        
        // Record transaction
        Transaction memory txn = Transaction({
            user: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            isDeposit: true
        });
        
        transactionHistory.push(txn);
        userTransactions[msg.sender].push(txn);
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Withdraw ETH with a 1% fee
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) external {
        UserAccount storage account = userAccounts[msg.sender];
        
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(account.balance >= amount, "Insufficient balance");
        
        // Calculate fee (1% of withdrawal amount)
        uint256 fee = (amount * feePercentage) / FEE_DENOMINATOR;
        uint256 netAmount = amount - fee;
        
        // Update balances
        account.balance -= amount;
        account.totalWithdrawn += amount;
        account.withdrawalCount++;
        account.lastWithdrawalTime = block.timestamp;
        
        totalFeesCollected += fee;
        
        // Record transaction
        Transaction memory txn = Transaction({
            user: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            isDeposit: false
        });
        
        transactionHistory.push(txn);
        userTransactions[msg.sender].push(txn);
        
        // Transfer net amount to user
        (bool success, ) = msg.sender.call{value: netAmount}("");
        require(success, "Withdrawal transfer failed");
        
        emit Withdrawal(msg.sender, amount, fee, netAmount, block.timestamp);
        emit FeeCollected(owner, fee);
    }
    
    /**
     * @dev Withdraw all user balance with fee
     */
    function withdrawAll() external {
        UserAccount storage account = userAccounts[msg.sender];
        
        require(account.balance > 0, "No balance to withdraw");
        
        uint256 amount = account.balance;
        uint256 fee = (amount * feePercentage) / FEE_DENOMINATOR;
        uint256 netAmount = amount - fee;
        
        account.balance = 0;
        account.totalWithdrawn += amount;
        account.withdrawalCount++;
        account.lastWithdrawalTime = block.timestamp;
        
        totalFeesCollected += fee;
        
        // Record transaction
        Transaction memory txn = Transaction({
            user: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            isDeposit: false
        });
        
        transactionHistory.push(txn);
        userTransactions[msg.sender].push(txn);
        
        // Transfer net amount to user
        (bool success, ) = msg.sender.call{value: netAmount}("");
        require(success, "Withdrawal transfer failed");
        
        emit Withdrawal(msg.sender, amount, fee, netAmount, block.timestamp);
        emit FeeCollected(owner, fee);
    }
    
    /**
     * @dev Owner withdraws collected fees
     * @param amount The amount of fees to withdraw
     */
    function withdrawFees(uint256 amount) external onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(amount <= totalFeesCollected, "Insufficient fees collected");
        
        totalFeesCollected -= amount;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        
        emit OwnerWithdrawal(owner, amount);
    }
    
    /**
     * @dev Owner withdraws all collected fees
     */
    function withdrawAllFees() external onlyOwner {
        require(totalFeesCollected > 0, "No fees to withdraw");
        
        uint256 amount = totalFeesCollected;
        totalFeesCollected = 0;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        
        emit OwnerWithdrawal(owner, amount);
    }
    
    /**
     * @dev Get user account details
     * @param user The user's address
     * @return balance Current balance
     * @return totalDeposited Total amount deposited
     * @return totalWithdrawn Total amount withdrawn
     * @return depositCount Number of deposits
     * @return withdrawalCount Number of withdrawals
     * @return lastDepositTime Last deposit timestamp
     * @return lastWithdrawalTime Last withdrawal timestamp
     */
    function getUserAccount(address user) external view returns (
        uint256 balance,
        uint256 totalDeposited,
        uint256 totalWithdrawn,
        uint256 depositCount,
        uint256 withdrawalCount,
        uint256 lastDepositTime,
        uint256 lastWithdrawalTime
    ) {
        UserAccount memory account = userAccounts[user];
        return (
            account.balance,
            account.totalDeposited,
            account.totalWithdrawn,
            account.depositCount,
            account.withdrawalCount,
            account.lastDepositTime,
            account.lastWithdrawalTime
        );
    }
    
    /**
     * @dev Get user balance
     * @param user The user's address
     * @return The user's balance
     */
    function getBalance(address user) external view returns (uint256) {
        return userAccounts[user].balance;
    }
    
    /**
     * @dev Get user's transaction history
     * @param user The user's address
     * @return Array of transactions
     */
    function getUserTransactions(address user) external view returns (Transaction[] memory) {
        return userTransactions[user];
    }
    
    /**
     * @dev Get all transaction history
     * @return Array of all transactions
     */
    function getAllTransactions() external view returns (Transaction[] memory) {
        return transactionHistory;
    }
    
    /**
     * @dev Calculate withdrawal fee for a given amount
     * @param amount The withdrawal amount
     * @return fee The fee amount
     * @return netAmount The amount after fee deduction
     */
    function calculateWithdrawalFee(uint256 amount) external view returns (uint256 fee, uint256 netAmount) {
        fee = (amount * feePercentage) / FEE_DENOMINATOR;
        netAmount = amount - fee;
        return (fee, netAmount);
    }
    
    /**
     * @dev Get total contract balance (excluding fees)
     * @return The total balance of all users plus fees
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get all depositors
     * @return Array of depositor addresses
     */
    function getDepositors() external view returns (address[] memory) {
        return depositors;
    }
    
    /**
     * @dev Get depositors with active balances
     * @return Array of addresses with non-zero balances
     */
    function getActiveDepositors() external view returns (address[] memory) {
        uint256 activeCount = 0;
        
        // Count active depositors
        for (uint256 i = 0; i < depositors.length; i++) {
            if (userAccounts[depositors[i]].balance > 0) {
                activeCount++;
            }
        }
        
        // Create array and populate
        address[] memory activeDepositorsList = new address[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < depositors.length; i++) {
            if (userAccounts[depositors[i]].balance > 0) {
                activeDepositorsList[index] = depositors[i];
                index++;
            }
        }
        
        return activeDepositorsList;
    }
    
    /**
     * @dev Get total deposits across all users
     * @return The total amount deposited
     */
    function getTotalDeposits() external view returns (uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < depositors.length; i++) {
            total += userAccounts[depositors[i]].totalDeposited;
        }
        
        return total;
    }
    
    /**
     * @dev Get total withdrawals across all users
     * @return The total amount withdrawn
     */
    function getTotalWithdrawals() external view returns (uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < depositors.length; i++) {
            total += userAccounts[depositors[i]].totalWithdrawn;
        }
        
        return total;
    }
    
    /**
     * @dev Get total active balances across all users
     * @return The total of all user balances
     */
    function getTotalActiveBalances() external view returns (uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < depositors.length; i++) {
            total += userAccounts[depositors[i]].balance;
        }
        
        return total;
    }
    
    /**
     * @dev Get number of depositors
     * @return The count of depositors
     */
    function getDepositorCount() external view returns (uint256) {
        return depositors.length;
    }
    
    /**
     * @dev Get number of active depositors (with balance > 0)
     * @return The count of active depositors
     */
    function getActiveDepositorCount() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < depositors.length; i++) {
            if (userAccounts[depositors[i]].balance > 0) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Get total number of transactions
     * @return The count of all transactions
     */
    function getTotalTransactions() external view returns (uint256) {
        return transactionHistory.length;
    }
    
    /**
     * @dev Check if an address has deposited before
     * @param user The user's address
     * @return Whether the user has deposited
     */
    function hasDeposited(address user) external view returns (bool) {
        return isDepositor[user];
    }
    
    /**
     * @dev Get the fee percentage
     * @return The current fee percentage
     */
    function getFeePercentage() external view returns (uint256) {
        return feePercentage;
    }
    
    /**
     * @dev Get total fees collected
     * @return The total fees collected by owner
     */
    function getTotalFeesCollected() external view returns (uint256) {
        return totalFeesCollected;
    }
}
