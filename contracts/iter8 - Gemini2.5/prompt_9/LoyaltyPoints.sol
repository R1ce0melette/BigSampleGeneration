// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LoyaltyPoints
 * @dev A contract for managing a simple loyalty points system.
 * The owner of the contract can grant and deduct points from users.
 */
contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) private _points;

    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Grants loyalty points to a user. Can only be called by the owner.
     * @param user The address of the user to receive points.
     * @param amount The number of points to grant.
     */
    function grantPoints(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "Cannot grant points to the zero address.");
        require(amount > 0, "Amount must be greater than zero.");

        _points[user] += amount;
        emit PointsGranted(user, amount);
    }

    /**
     * @dev Deducts loyalty points from a user. Can only be called by the owner.
     * @param user The address of the user to deduct points from.
     * @param amount The number of points to deduct.
     */
    function deductPoints(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "Cannot deduct points from the zero address.");
        require(amount > 0, "Amount must be greater than zero.");
        require(_points[user] >= amount, "Insufficient points.");

        _points[user] -= amount;
        emit PointsDeducted(user, amount);
    }

    /**
     * @dev Retrieves the points balance for a given user.
     * @param user The address of the user to query.
     * @return The points balance of the user.
     */
    function getPoints(address user) public view returns (uint256) {
        return _points[user];
    }
}
