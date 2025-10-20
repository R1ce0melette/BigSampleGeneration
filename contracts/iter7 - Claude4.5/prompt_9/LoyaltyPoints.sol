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
    
    // Total points issued in the system
    uint256 public totalPointsIssued;
    
    // Events
    event PointsGranted(address indexed user, uint256 amount, uint256 newBalance);
    event PointsDeducted(address indexed user, uint256 amount, uint256 newBalance);
    event PointsTransferred(address indexed from, address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    /**
     * @dev Constructor sets the contract owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Grant points to a user (only owner)
     * @param user The address to grant points to
     * @param amount The amount of points to grant
     */
    function grantPoints(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Cannot grant points to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        points[user] += amount;
        totalPointsIssued += amount;
        
        emit PointsGranted(user, amount, points[user]);
    }
    
    /**
     * @dev Grant points to multiple users (only owner)
     * @param users Array of addresses to grant points to
     * @param amounts Array of amounts to grant (must match users array length)
     */
    function grantPointsBatch(address[] memory users, uint256[] memory amounts) external onlyOwner {
        require(users.length == amounts.length, "Arrays length mismatch");
        require(users.length > 0, "Arrays cannot be empty");
        
        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Cannot grant points to zero address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            points[users[i]] += amounts[i];
            totalPointsIssued += amounts[i];
            
            emit PointsGranted(users[i], amounts[i], points[users[i]]);
        }
    }
    
    /**
     * @dev Deduct points from a user (only owner)
     * @param user The address to deduct points from
     * @param amount The amount of points to deduct
     */
    function deductPoints(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Cannot deduct points from zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(points[user] >= amount, "Insufficient points balance");
        
        points[user] -= amount;
        totalPointsIssued -= amount;
        
        emit PointsDeducted(user, amount, points[user]);
    }
    
    /**
     * @dev Transfer points to another user
     * @param to The address to transfer points to
     * @param amount The amount of points to transfer
     */
    function transferPoints(address to, uint256 amount) external {
        require(to != address(0), "Cannot transfer to zero address");
        require(to != msg.sender, "Cannot transfer to yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(points[msg.sender] >= amount, "Insufficient points balance");
        
        points[msg.sender] -= amount;
        points[to] += amount;
        
        emit PointsTransferred(msg.sender, to, amount);
    }
    
    /**
     * @dev Get the points balance of a user
     * @param user The address to query
     * @return The points balance
     */
    function getPoints(address user) external view returns (uint256) {
        return points[user];
    }
    
    /**
     * @dev Get the points balance of the caller
     * @return The points balance of msg.sender
     */
    function getMyPoints() external view returns (uint256) {
        return points[msg.sender];
    }
    
    /**
     * @dev Transfer ownership of the contract (only owner)
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner is the same as current owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Set points balance for a user directly (only owner)
     * @param user The address to set points for
     * @param amount The new points balance
     */
    function setPoints(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Cannot set points for zero address");
        
        uint256 oldBalance = points[user];
        points[user] = amount;
        
        // Update total points issued
        if (amount > oldBalance) {
            totalPointsIssued += (amount - oldBalance);
            emit PointsGranted(user, amount - oldBalance, amount);
        } else if (amount < oldBalance) {
            totalPointsIssued -= (oldBalance - amount);
            emit PointsDeducted(user, oldBalance - amount, amount);
        }
    }
}
