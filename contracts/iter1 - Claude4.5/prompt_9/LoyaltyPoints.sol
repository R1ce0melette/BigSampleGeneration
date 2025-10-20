// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LoyaltyPoints
 * @dev A loyalty points system where the owner can grant and deduct points from users
 */
contract LoyaltyPoints {
    address public owner;
    
    mapping(address => uint256) public points;
    mapping(address => bool) public isRegistered;
    address[] private users;
    
    uint256 public totalPointsIssued;
    uint256 public totalPointsRedeemed;
    
    struct Transaction {
        address user;
        int256 amount;
        uint256 timestamp;
        string reason;
    }
    
    Transaction[] public transactions;
    mapping(address => uint256[]) private userTransactionIds;
    
    event PointsGranted(address indexed user, uint256 amount, string reason);
    event PointsDeducted(address indexed user, uint256 amount, string reason);
    event UserRegistered(address indexed user);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new user
     * @param user The address of the user to register
     */
    function registerUser(address user) external onlyOwner {
        require(user != address(0), "Invalid address");
        require(!isRegistered[user], "User already registered");
        
        isRegistered[user] = true;
        users.push(user);
        
        emit UserRegistered(user);
    }
    
    /**
     * @dev Grant points to a user
     * @param user The address of the user
     * @param amount The number of points to grant
     * @param reason The reason for granting points
     */
    function grantPoints(address user, uint256 amount, string memory reason) external onlyOwner {
        require(user != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        
        if (!isRegistered[user]) {
            isRegistered[user] = true;
            users.push(user);
            emit UserRegistered(user);
        }
        
        points[user] += amount;
        totalPointsIssued += amount;
        
        _recordTransaction(user, int256(amount), reason);
        
        emit PointsGranted(user, amount, reason);
    }
    
    /**
     * @dev Deduct points from a user
     * @param user The address of the user
     * @param amount The number of points to deduct
     * @param reason The reason for deducting points
     */
    function deductPoints(address user, uint256 amount, string memory reason) external onlyOwner {
        require(user != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(isRegistered[user], "User not registered");
        require(points[user] >= amount, "Insufficient points");
        
        points[user] -= amount;
        totalPointsRedeemed += amount;
        
        _recordTransaction(user, -int256(amount), reason);
        
        emit PointsDeducted(user, amount, reason);
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    /**
     * @dev Get points balance for a user
     * @param user The address of the user
     * @return The points balance
     */
    function getPoints(address user) external view returns (uint256) {
        return points[user];
    }
    
    /**
     * @dev Get all registered users
     * @return Array of registered user addresses
     */
    function getAllUsers() external view returns (address[] memory) {
        return users;
    }
    
    /**
     * @dev Get the total number of registered users
     * @return The count of registered users
     */
    function getUserCount() external view returns (uint256) {
        return users.length;
    }
    
    /**
     * @dev Get transaction history for a user
     * @param user The address of the user
     * @return Array of transaction IDs
     */
    function getUserTransactions(address user) external view returns (uint256[] memory) {
        return userTransactionIds[user];
    }
    
    /**
     * @dev Get details of a specific transaction
     * @param transactionId The ID of the transaction
     * @return user The user address
     * @return amount The amount (positive for granted, negative for deducted)
     * @return timestamp When the transaction occurred
     * @return reason The reason for the transaction
     */
    function getTransaction(uint256 transactionId) external view returns (
        address user,
        int256 amount,
        uint256 timestamp,
        string memory reason
    ) {
        require(transactionId < transactions.length, "Transaction does not exist");
        
        Transaction memory txn = transactions[transactionId];
        
        return (
            txn.user,
            txn.amount,
            txn.timestamp,
            txn.reason
        );
    }
    
    /**
     * @dev Get all transactions
     * @return Array of all transactions
     */
    function getAllTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }
    
    /**
     * @dev Get total number of transactions
     * @return The count of transactions
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
    
    /**
     * @dev Get system statistics
     * @return _totalPointsIssued Total points granted
     * @return _totalPointsRedeemed Total points deducted
     * @return _activePoints Currently active points
     * @return _userCount Number of registered users
     */
    function getSystemStats() external view returns (
        uint256 _totalPointsIssued,
        uint256 _totalPointsRedeemed,
        uint256 _activePoints,
        uint256 _userCount
    ) {
        return (
            totalPointsIssued,
            totalPointsRedeemed,
            totalPointsIssued - totalPointsRedeemed,
            users.length
        );
    }
    
    /**
     * @dev Internal function to record a transaction
     * @param user The user address
     * @param amount The amount (positive or negative)
     * @param reason The reason for the transaction
     */
    function _recordTransaction(address user, int256 amount, string memory reason) private {
        uint256 transactionId = transactions.length;
        
        transactions.push(Transaction({
            user: user,
            amount: amount,
            timestamp: block.timestamp,
            reason: reason
        }));
        
        userTransactionIds[user].push(transactionId);
    }
}
