// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) public points;

    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function grantPoints(address user, uint256 amount) external onlyOwner {
        points[user] += amount;
        emit PointsGranted(user, amount);
    }

    function deductPoints(address user, uint256 amount) external onlyOwner {
        require(points[user] >= amount, "Insufficient points");
        points[user] -= amount;
        emit PointsDeducted(user, amount);
    }

    function getPoints(address user) external view returns (uint256) {
        return points[user];
    }
}
