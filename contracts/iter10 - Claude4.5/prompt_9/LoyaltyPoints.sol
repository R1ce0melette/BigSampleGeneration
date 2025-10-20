// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) public points;
    mapping(address => bool) public isRegistered;
    uint256 public totalUsers;

    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);
    event UserRegistered(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerUser() external {
        require(!isRegistered[msg.sender], "User already registered");
        
        isRegistered[msg.sender] = true;
        totalUsers++;

        emit UserRegistered(msg.sender);
    }

    function grantPoints(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");

        if (!isRegistered[user]) {
            isRegistered[user] = true;
            totalUsers++;
            emit UserRegistered(user);
        }

        points[user] += amount;

        emit PointsGranted(user, amount);
    }

    function deductPoints(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(isRegistered[user], "User not registered");
        require(points[user] >= amount, "Insufficient points");

        points[user] -= amount;

        emit PointsDeducted(user, amount);
    }

    function getPoints(address user) external view returns (uint256) {
        return points[user];
    }

    function transferPoints(address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to yourself");
        require(isRegistered[msg.sender], "Sender not registered");
        require(amount > 0, "Amount must be greater than 0");
        require(points[msg.sender] >= amount, "Insufficient points");

        if (!isRegistered[to]) {
            isRegistered[to] = true;
            totalUsers++;
            emit UserRegistered(to);
        }

        points[msg.sender] -= amount;
        points[to] += amount;

        emit PointsDeducted(msg.sender, amount);
        emit PointsGranted(to, amount);
    }
}
