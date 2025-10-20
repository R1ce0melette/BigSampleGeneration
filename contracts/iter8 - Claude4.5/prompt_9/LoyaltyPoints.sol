// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LoyaltyPoints
 * @dev Loyalty points system where owner can grant and deduct points from users
 */
contract LoyaltyPoints {
    // Transaction structure
    struct Transaction {
        address user;
        int256 amount;
        string reason;
        uint256 timestamp;
        bool isGrant;
    }

    // State variables
    address public owner;
    mapping(address => uint256) private points;
    mapping(address => Transaction[]) private userTransactions;
    Transaction[] private allTransactions;
    
    address[] private users;
    mapping(address => bool) private isUser;

    // Events
    event PointsGranted(address indexed user, uint256 amount, string reason, uint256 timestamp);
    event PointsDeducted(address indexed user, uint256 amount, string reason, uint256 timestamp);
    event PointsTransferred(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Grant points to a user
     * @param user User address
     * @param amount Points to grant
     * @param reason Reason for granting
     */
    function grantPoints(address user, uint256 amount, string memory reason) public onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");

        if (!isUser[user]) {
            users.push(user);
            isUser[user] = true;
        }

        points[user] += amount;

        Transaction memory txn = Transaction({
            user: user,
            amount: int256(amount),
            reason: reason,
            timestamp: block.timestamp,
            isGrant: true
        });

        userTransactions[user].push(txn);
        allTransactions.push(txn);

        emit PointsGranted(user, amount, reason, block.timestamp);
    }

    /**
     * @dev Deduct points from a user
     * @param user User address
     * @param amount Points to deduct
     * @param reason Reason for deduction
     */
    function deductPoints(address user, uint256 amount, string memory reason) public onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(points[user] >= amount, "Insufficient points");

        points[user] -= amount;

        Transaction memory txn = Transaction({
            user: user,
            amount: -int256(amount),
            reason: reason,
            timestamp: block.timestamp,
            isGrant: false
        });

        userTransactions[user].push(txn);
        allTransactions.push(txn);

        emit PointsDeducted(user, amount, reason, block.timestamp);
    }

    /**
     * @dev Transfer points between users
     * @param to Recipient address
     * @param amount Points to transfer
     */
    function transferPoints(address to, uint256 amount) public {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(points[msg.sender] >= amount, "Insufficient points");

        if (!isUser[to]) {
            users.push(to);
            isUser[to] = true;
        }

        points[msg.sender] -= amount;
        points[to] += amount;

        Transaction memory deductTxn = Transaction({
            user: msg.sender,
            amount: -int256(amount),
            reason: "Transfer to user",
            timestamp: block.timestamp,
            isGrant: false
        });

        Transaction memory grantTxn = Transaction({
            user: to,
            amount: int256(amount),
            reason: "Transfer from user",
            timestamp: block.timestamp,
            isGrant: true
        });

        userTransactions[msg.sender].push(deductTxn);
        userTransactions[to].push(grantTxn);
        allTransactions.push(deductTxn);
        allTransactions.push(grantTxn);

        emit PointsTransferred(msg.sender, to, amount, block.timestamp);
    }

    /**
     * @dev Batch grant points to multiple users
     * @param users_ Array of user addresses
     * @param amounts Array of amounts
     * @param reason Reason for granting
     */
    function batchGrantPoints(address[] memory users_, uint256[] memory amounts, string memory reason) public onlyOwner {
        require(users_.length == amounts.length, "Arrays length mismatch");
        require(users_.length > 0, "Empty arrays");

        for (uint256 i = 0; i < users_.length; i++) {
            if (users_[i] != address(0) && amounts[i] > 0) {
                grantPoints(users_[i], amounts[i], reason);
            }
        }
    }

    /**
     * @dev Get points balance of a user
     * @param user User address
     * @return Points balance
     */
    function getPoints(address user) public view returns (uint256) {
        return points[user];
    }

    /**
     * @dev Get caller's points balance
     * @return Points balance
     */
    function getMyPoints() public view returns (uint256) {
        return points[msg.sender];
    }

    /**
     * @dev Get user transaction history
     * @param user User address
     * @return Array of transactions
     */
    function getUserTransactions(address user) public view returns (Transaction[] memory) {
        return userTransactions[user];
    }

    /**
     * @dev Get caller's transaction history
     * @return Array of transactions
     */
    function getMyTransactions() public view returns (Transaction[] memory) {
        return userTransactions[msg.sender];
    }

    /**
     * @dev Get all transactions
     * @return Array of all transactions
     */
    function getAllTransactions() public view returns (Transaction[] memory) {
        return allTransactions;
    }

    /**
     * @dev Get all users
     * @return Array of user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    /**
     * @dev Get total number of users
     * @return Total user count
     */
    function getTotalUsers() public view returns (uint256) {
        return users.length;
    }

    /**
     * @dev Get total points in circulation
     * @return Total points
     */
    function getTotalPoints() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < users.length; i++) {
            total += points[users[i]];
        }
        return total;
    }

    /**
     * @dev Get top users by points
     * @param n Number of top users to return
     * @return addresses Array of addresses
     * @return pointsBalances Array of points balances
     */
    function getTopUsers(uint256 n) public view returns (address[] memory addresses, uint256[] memory pointsBalances) {
        uint256 userCount = users.length;
        if (n > userCount) {
            n = userCount;
        }

        addresses = new address[](n);
        pointsBalances = new uint256[](n);

        // Simple selection sort for top N
        for (uint256 i = 0; i < n; i++) {
            uint256 maxPoints = 0;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < userCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (addresses[k] == users[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && points[users[j]] > maxPoints) {
                    maxPoints = points[users[j]];
                    maxIndex = j;
                }
            }

            if (maxPoints > 0) {
                addresses[i] = users[maxIndex];
                pointsBalances[i] = maxPoints;
            }
        }

        return (addresses, pointsBalances);
    }

    /**
     * @dev Get users with points greater than threshold
     * @param threshold Minimum points threshold
     * @return Array of user addresses
     */
    function getUsersAboveThreshold(uint256 threshold) public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (points[users[i]] > threshold) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (points[users[i]] > threshold) {
                result[index] = users[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Check if user has enough points
     * @param user User address
     * @param amount Amount to check
     * @return true if user has enough points
     */
    function hasEnoughPoints(address user, uint256 amount) public view returns (bool) {
        return points[user] >= amount;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }
}
