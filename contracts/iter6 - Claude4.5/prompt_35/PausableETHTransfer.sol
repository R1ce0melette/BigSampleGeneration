// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PausableETHTransfer
 * @dev A contract that allows the owner to pause and resume ETH transfers for safety control
 */
contract PausableETHTransfer {
    address public owner;
    bool public isPaused;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public totalDeposited;
    mapping(address => uint256) public totalWithdrawn;
    mapping(address => uint256) public totalTransfersSent;
    mapping(address => uint256) public totalTransfersReceived;
    
    struct TransferRecord {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        TransferType transferType;
    }
    
    enum TransferType {
        Deposit,
        Withdrawal,
        Transfer
    }
    
    TransferRecord[] public transferHistory;
    mapping(address => uint256[]) public userTransferHistory;
    
    // Events
    event Paused(address indexed owner, uint256 timestamp);
    event Unpaused(address indexed owner, uint256 timestamp);
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(isPaused, "Contract is not paused");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        isPaused = false;
    }
    
    /**
     * @dev Pause all transfers
     */
    function pause() external onlyOwner whenNotPaused {
        isPaused = true;
        emit Paused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Resume all transfers
     */
    function unpause() external onlyOwner whenPaused {
        isPaused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposited[msg.sender] += msg.value;
        
        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: msg.sender,
            to: address(this),
            amount: msg.value,
            timestamp: block.timestamp,
            transferType: TransferType.Deposit
        });
        
        transferHistory.push(record);
        userTransferHistory[msg.sender].push(transferHistory.length - 1);
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Withdraw ETH from the contract
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        totalWithdrawn[msg.sender] += amount;
        
        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: address(this),
            to: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            transferType: TransferType.Withdrawal
        });
        
        transferHistory.push(record);
        userTransferHistory[msg.sender].push(transferHistory.length - 1);
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Withdraw all balance
     */
    function withdrawAll() external whenNotPaused {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        totalWithdrawn[msg.sender] += amount;
        
        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: address(this),
            to: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            transferType: TransferType.Withdrawal
        });
        
        transferHistory.push(record);
        userTransferHistory[msg.sender].push(transferHistory.length - 1);
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Transfer ETH to another user within the contract
     * @param to The recipient address
     * @param amount The amount to transfer
     */
    function transfer(address to, uint256 amount) external whenNotPaused {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to yourself");
        require(amount > 0, "Transfer amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        totalTransfersSent[msg.sender] += amount;
        totalTransfersReceived[to] += amount;
        
        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: msg.sender,
            to: to,
            amount: amount,
            timestamp: block.timestamp,
            transferType: TransferType.Transfer
        });
        
        transferHistory.push(record);
        userTransferHistory[msg.sender].push(transferHistory.length - 1);
        userTransferHistory[to].push(transferHistory.length - 1);
        
        emit Transfer(msg.sender, to, amount, block.timestamp);
    }
    
    /**
     * @dev Emergency withdraw by owner (only when paused)
     * @param user The user address
     * @param amount The amount to withdraw
     */
    function emergencyWithdraw(address user, uint256 amount) external onlyOwner whenPaused {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[user] >= amount, "Insufficient user balance");
        
        balances[user] -= amount;
        totalWithdrawn[user] += amount;
        
        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: address(this),
            to: user,
            amount: amount,
            timestamp: block.timestamp,
            transferType: TransferType.Withdrawal
        });
        
        transferHistory.push(record);
        userTransferHistory[user].push(transferHistory.length - 1);
        
        (bool success, ) = payable(user).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(user, amount, block.timestamp);
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
     * @dev Get user statistics
     * @param user The user address
     * @return balance Current balance
     * @return deposited Total deposited
     * @return withdrawn Total withdrawn
     * @return transfersSent Total transfers sent
     * @return transfersReceived Total transfers received
     */
    function getUserStats(address user) external view returns (
        uint256 balance,
        uint256 deposited,
        uint256 withdrawn,
        uint256 transfersSent,
        uint256 transfersReceived
    ) {
        return (
            balances[user],
            totalDeposited[user],
            totalWithdrawn[user],
            totalTransfersSent[user],
            totalTransfersReceived[user]
        );
    }
    
    /**
     * @dev Get user transfer history
     * @param user The user address
     * @return Array of transfer record indices
     */
    function getUserTransferHistory(address user) external view returns (uint256[] memory) {
        return userTransferHistory[user];
    }
    
    /**
     * @dev Get transfer record
     * @param index The transfer record index
     * @return from Sender address
     * @return to Recipient address
     * @return amount Transfer amount
     * @return timestamp Transfer timestamp
     * @return transferType Type of transfer
     */
    function getTransferRecord(uint256 index) external view returns (
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        TransferType transferType
    ) {
        require(index < transferHistory.length, "Invalid index");
        
        TransferRecord memory record = transferHistory[index];
        
        return (
            record.from,
            record.to,
            record.amount,
            record.timestamp,
            record.transferType
        );
    }
    
    /**
     * @dev Get total transfer history count
     * @return Total number of transfer records
     */
    function getTotalTransferCount() external view returns (uint256) {
        return transferHistory.length;
    }
    
    /**
     * @dev Get contract balance
     * @return Contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get pause status
     * @return True if paused, false otherwise
     */
    function getPauseStatus() external view returns (bool) {
        return isPaused;
    }
    
    /**
     * @dev Check if transfers are allowed
     * @return True if transfers are allowed
     */
    function areTransfersAllowed() external view returns (bool) {
        return !isPaused;
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
     * @dev Receive function to accept ETH deposits
     */
    receive() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposited[msg.sender] += msg.value;
        
        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: msg.sender,
            to: address(this),
            amount: msg.value,
            timestamp: block.timestamp,
            transferType: TransferType.Deposit
        });
        
        transferHistory.push(record);
        userTransferHistory[msg.sender].push(transferHistory.length - 1);
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposited[msg.sender] += msg.value;
        
        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: msg.sender,
            to: address(this),
            amount: msg.value,
            timestamp: block.timestamp,
            transferType: TransferType.Deposit
        });
        
        transferHistory.push(record);
        userTransferHistory[msg.sender].push(transferHistory.length - 1);
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
}
