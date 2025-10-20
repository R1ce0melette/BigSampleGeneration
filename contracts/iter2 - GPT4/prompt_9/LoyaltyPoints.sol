// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) public points;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function grantPoints(address user, uint256 amount) external onlyOwner {
        points[user] += amount;
    }

    function deductPoints(address user, uint256 amount) external onlyOwner {
        require(points[user] >= amount, "Insufficient points");
        points[user] -= amount;
    }
}
