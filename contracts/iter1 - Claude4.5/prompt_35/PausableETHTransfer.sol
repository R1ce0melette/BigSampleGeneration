// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PausableETHTransfer
 * @dev A contract that allows the owner to pause and resume ETH transfers for safety control
 */
contract PausableETHTransfer {
    struct Transfer {
        uint256 id;
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        string purpose;
    }
    
    struct UserBalance {
        uint256 balance;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 totalSent;
        uint256 totalReceived;
    }
    
    address public owner;
    bool public paused;
    
    mapping(address => UserBalance) public userBalances;
    Transfer[] private transferHistory;
    mapping(address => Transfer[]) private userSentTransfers;
    mapping(address => Transfer[]) private userReceivedTransfers;
    
    uint256 private transferCounter;
    
    event Paused(address indexed owner, uint256 timestamp);
    event Unpaused(address indexed owner, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    
    event TransferExecuted(
        uint256 indexed transferId,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
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
    
    /**
     * @dev Pause all transfers
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Resume all transfers
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        UserBalance storage userBalance = userBalances[msg.sender];
        userBalance.balance += msg.value;
        userBalance.totalDeposited += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Withdraw ETH from the contract
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        
        UserBalance storage userBalance = userBalances[msg.sender];
        require(userBalance.balance >= amount, "Insufficient balance");
        
        userBalance.balance -= amount;
        userBalance.totalWithdrawn += amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal transfer failed");
        
        emit Withdrawn(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Withdraw all balance from the contract
     */
    function withdrawAll() external whenNotPaused {
        UserBalance storage userBalance = userBalances[msg.sender];
        uint256 amount = userBalance.balance;
        
        require(amount > 0, "No balance to withdraw");
        
        userBalance.balance = 0;
        userBalance.totalWithdrawn += amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal transfer failed");
        
        emit Withdrawn(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Transfer ETH to another user within the contract
     * @param to The recipient's address
     * @param amount The amount to transfer
     * @param purpose Optional purpose description
     */
    function transfer(address to, uint256 amount, string memory purpose) external whenNotPaused {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to yourself");
        require(amount > 0, "Transfer amount must be greater than 0");
        
        UserBalance storage senderBalance = userBalances[msg.sender];
        require(senderBalance.balance >= amount, "Insufficient balance");
        
        senderBalance.balance -= amount;
        senderBalance.totalSent += amount;
        
        UserBalance storage recipientBalance = userBalances[to];
        recipientBalance.balance += amount;
        recipientBalance.totalReceived += amount;
        
        transferCounter++;
        
        Transfer memory newTransfer = Transfer({
            id: transferCounter,
            from: msg.sender,
            to: to,
            amount: amount,
            timestamp: block.timestamp,
            purpose: purpose
        });
        
        transferHistory.push(newTransfer);
        userSentTransfers[msg.sender].push(newTransfer);
        userReceivedTransfers[to].push(newTransfer);
        
        emit TransferExecuted(transferCounter, msg.sender, to, amount, block.timestamp);
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Get user balance details
     * @param user The user's address
     * @return balance Current balance
     * @return totalDeposited Total deposited
     * @return totalWithdrawn Total withdrawn
     * @return totalSent Total sent to others
     * @return totalReceived Total received from others
     */
    function getUserBalance(address user) external view returns (
        uint256 balance,
        uint256 totalDeposited,
        uint256 totalWithdrawn,
        uint256 totalSent,
        uint256 totalReceived
    ) {
        UserBalance memory userBalance = userBalances[user];
        return (
            userBalance.balance,
            userBalance.totalDeposited,
            userBalance.totalWithdrawn,
            userBalance.totalSent,
            userBalance.totalReceived
        );
    }
    
    /**
     * @dev Get balance of a user
     * @param user The user's address
     * @return The user's balance
     */
    function balanceOf(address user) external view returns (uint256) {
        return userBalances[user].balance;
    }
    
    /**
     * @dev Get all transfer history
     * @return Array of all transfers
     */
    function getAllTransfers() external view returns (Transfer[] memory) {
        return transferHistory;
    }
    
    /**
     * @dev Get transfers sent by a user
     * @param user The user's address
     * @return Array of sent transfers
     */
    function getSentTransfers(address user) external view returns (Transfer[] memory) {
        return userSentTransfers[user];
    }
    
    /**
     * @dev Get transfers received by a user
     * @param user The user's address
     * @return Array of received transfers
     */
    function getReceivedTransfers(address user) external view returns (Transfer[] memory) {
        return userReceivedTransfers[user];
    }
    
    /**
     * @dev Get a specific transfer by ID
     * @param transferId The ID of the transfer
     * @return id Transfer ID
     * @return from Sender address
     * @return to Recipient address
     * @return amount Transfer amount
     * @return timestamp Transfer timestamp
     * @return purpose Transfer purpose
     */
    function getTransfer(uint256 transferId) external view returns (
        uint256 id,
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        string memory purpose
    ) {
        require(transferId > 0 && transferId <= transferCounter, "Transfer does not exist");
        
        Transfer memory txn = transferHistory[transferId - 1];
        return (txn.id, txn.from, txn.to, txn.amount, txn.timestamp, txn.purpose);
    }
    
    /**
     * @dev Get contract's total ETH balance
     * @return The total ETH in the contract
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get total number of transfers
     * @return The transfer count
     */
    function getTotalTransfers() external view returns (uint256) {
        return transferCounter;
    }
    
    /**
     * @dev Check if contract is paused
     * @return Whether the contract is paused
     */
    function isPaused() external view returns (bool) {
        return paused;
    }
    
    /**
     * @dev Get recent transfers (last N)
     * @param count Number of recent transfers to return
     * @return Array of recent transfers
     */
    function getRecentTransfers(uint256 count) external view returns (Transfer[] memory) {
        if (transferHistory.length == 0) {
            return new Transfer[](0);
        }
        
        uint256 resultCount = count > transferHistory.length ? transferHistory.length : count;
        Transfer[] memory result = new Transfer[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = transferHistory[transferHistory.length - 1 - i];
        }
        
        return result;
    }
    
    /**
     * @dev Get transfers between two addresses
     * @param from The sender's address
     * @param to The recipient's address
     * @return Array of transfers from sender to recipient
     */
    function getTransfersBetween(address from, address to) external view returns (Transfer[] memory) {
        Transfer[] memory sentTransfers = userSentTransfers[from];
        uint256 matchCount = 0;
        
        // Count matching transfers
        for (uint256 i = 0; i < sentTransfers.length; i++) {
            if (sentTransfers[i].to == to) {
                matchCount++;
            }
        }
        
        // Create array and populate
        Transfer[] memory result = new Transfer[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < sentTransfers.length; i++) {
            if (sentTransfers[i].to == to) {
                result[index] = sentTransfers[i];
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Get total deposited across all users
     * @return Total ETH deposited
     */
    function getTotalDeposited() external view returns (uint256) {
        // Note: This would require tracking all users
        // For now, returns contract balance as approximation
        return address(this).balance;
    }
    
    /**
     * @dev Emergency withdraw by owner (only when paused)
     * @param amount The amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner whenPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Emergency withdrawal failed");
    }
    
    /**
     * @dev Receive ETH directly (acts as deposit)
     */
    receive() external payable {
        require(!paused, "Contract is paused");
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        UserBalance storage userBalance = userBalances[msg.sender];
        userBalance.balance += msg.value;
        userBalance.totalDeposited += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        require(!paused, "Contract is paused");
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        UserBalance storage userBalance = userBalances[msg.sender];
        userBalance.balance += msg.value;
        userBalance.totalDeposited += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
}
