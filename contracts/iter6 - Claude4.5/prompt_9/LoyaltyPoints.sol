// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LoyaltyPoints
 * @dev A loyalty points system where the owner can grant and deduct points from users
 */
contract LoyaltyPoints {
    address public owner;
    
    // Mapping to track points balance for each user
    mapping(address => uint256) public points;
    
    // Mapping to track total points earned (lifetime)
    mapping(address => uint256) public totalPointsEarned;
    
    // Mapping to track total points spent (lifetime)
    mapping(address => uint256) public totalPointsSpent;
    
    // Events
    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Grant points to a user
     * @param user The address of the user
     * @param amount The amount of points to grant
     */
    function grantPoints(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Cannot grant points to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        points[user] += amount;
        totalPointsEarned[user] += amount;
        
        emit PointsGranted(user, amount);
    }
    
    /**
     * @dev Grant points to multiple users at once
     * @param users Array of user addresses
     * @param amounts Array of point amounts (must match users array length)
     */
    function grantPointsBatch(address[] memory users, uint256[] memory amounts) external onlyOwner {
        require(users.length == amounts.length, "Arrays length mismatch");
        require(users.length > 0, "Arrays cannot be empty");
        
        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Cannot grant points to zero address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            points[users[i]] += amounts[i];
            totalPointsEarned[users[i]] += amounts[i];
            
            emit PointsGranted(users[i], amounts[i]);
        }
    }
    
    /**
     * @dev Deduct points from a user
     * @param user The address of the user
     * @param amount The amount of points to deduct
     */
    function deductPoints(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Cannot deduct points from zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(points[user] >= amount, "Insufficient points balance");
        
        points[user] -= amount;
        totalPointsSpent[user] += amount;
        
        emit PointsDeducted(user, amount);
    }
    
    /**
     * @dev Get the points balance of a user
     * @param user The address of the user
     * @return The points balance
     */
    function getPoints(address user) external view returns (uint256) {
        return points[user];
    }
    
    /**
     * @dev Get the total points earned by a user (lifetime)
     * @param user The address of the user
     * @return The total points earned
     */
    function getTotalPointsEarned(address user) external view returns (uint256) {
        return totalPointsEarned[user];
    }
    
    /**
     * @dev Get the total points spent by a user (lifetime)
     * @param user The address of the user
     * @return The total points spent
     */
    function getTotalPointsSpent(address user) external view returns (uint256) {
        return totalPointsSpent[user];
    }
    
    /**
     * @dev Get comprehensive user stats
     * @param user The address of the user
     * @return currentBalance Current points balance
     * @return totalEarned Total points earned (lifetime)
     * @return totalSpent Total points spent (lifetime)
     */
    function getUserStats(address user) external view returns (
        uint256 currentBalance,
        uint256 totalEarned,
        uint256 totalSpent
    ) {
        return (
            points[user],
            totalPointsEarned[user],
            totalPointsSpent[user]
        );
    }
    
    /**
     * @dev Get the caller's points balance
     * @return The points balance of the caller
     */
    function getMyPoints() external view returns (uint256) {
        return points[msg.sender];
    }
    
    /**
     * @dev Get the caller's comprehensive stats
     * @return currentBalance Current points balance
     * @return totalEarned Total points earned (lifetime)
     * @return totalSpent Total points spent (lifetime)
     */
    function getMyStats() external view returns (
        uint256 currentBalance,
        uint256 totalEarned,
        uint256 totalSpent
    ) {
        return (
            points[msg.sender],
            totalPointsEarned[msg.sender],
            totalPointsSpent[msg.sender]
        );
    }
    
    /**
     * @dev Transfer ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner is the same as current owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
