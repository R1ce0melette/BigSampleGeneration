// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LoyaltyPoints
 * @dev A contract for managing a simple loyalty points system.
 * The owner of the contract can grant and deduct points from users.
 */
contract LoyaltyPoints {
    // The address of the contract owner
    address public owner;

    // Mapping from user address to their points balance
    mapping(address => uint256) private _points;

    /**
     * @dev Emitted when points are granted to a user.
     * @param user The address of the user receiving points.
     * @param amount The number of points granted.
     */
    event PointsGranted(address indexed user, uint256 amount);

    /**
     * @dev Emitted when points are deducted from a user.
     * @param user The address of the user losing points.
     * @param amount The number of points deducted.
     */
    event PointsDeducted(address indexed user, uint256 amount);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "LoyaltyPoints: Caller is not the owner.");
        _;
    }

    /**
     * @dev Sets the contract owner to the deployer's address.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Grants loyalty points to a user. Can only be called by the owner.
     * @param user The address of the user to receive points.
     * @param amount The number of points to grant.
     */
    function grantPoints(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "LoyaltyPoints: Cannot grant points to the zero address.");
        require(amount > 0, "LoyaltyPoints: Amount must be greater than zero.");

        _points[user] += amount;
        emit PointsGranted(user, amount);
    }

    /**
     * @dev Deducts loyalty points from a user. Can only be called by the owner.
     * @param user The address of the user to deduct points from.
     * @param amount The number of points to deduct.
     */
    function deductPoints(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "LoyaltyPoints: Cannot deduct points from the zero address.");
        require(amount > 0, "LoyaltyPoints: Amount must be greater than zero.");
        require(_points[user] >= amount, "LoyaltyPoints: Insufficient points.");

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
