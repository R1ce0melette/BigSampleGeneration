// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LoyaltyPoints
 * @dev A contract for managing a loyalty points system.
 */
contract LoyaltyPoints {
    // Address of the contract owner who can manage points.
    address public owner;
    // Mapping from a user's address to their points balance.
    mapping(address => uint256) public userPoints;

    /**
     * @dev Event emitted when points are granted to a user.
     * @param user The address of the user receiving points.
     * @param points The number of points granted.
     * @param newTotal The new total points balance of the user.
     */
    event PointsGranted(address indexed user, uint256 points, uint256 newTotal);

    /**
     * @dev Event emitted when points are deducted from a user.
     * @param user The address of the user losing points.
     * @param points The number of points deducted.
     * @param newTotal The new total points balance of the user.
     */
    event PointsDeducted(address indexed user, uint256 points, uint256 newTotal);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the contract owner upon deployment.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Grants loyalty points to a specified user.
     * - Only the owner can grant points.
     * @param _user The address of the user to receive points.
     * @param _points The number of points to grant.
     */
    function grantPoints(address _user, uint256 _points) public onlyOwner {
        require(_user != address(0), "Cannot grant points to the zero address.");
        require(_points > 0, "Points to grant must be positive.");

        userPoints[_user] += _points;
        emit PointsGranted(_user, _points, userPoints[_user]);
    }

    /**
     * @dev Deducts loyalty points from a specified user.
     * - Only the owner can deduct points.
     * - The user must have enough points to be deducted.
     * @param _user The address of the user from whom to deduct points.
     * @param _points The number of points to deduct.
     */
    function deductPoints(address _user, uint256 _points) public onlyOwner {
        require(_user != address(0), "Cannot deduct points from the zero address.");
        require(_points > 0, "Points to deduct must be positive.");
        require(userPoints[_user] >= _points, "User does not have enough points.");

        userPoints[_user] -= _points;
        emit PointsDeducted(_user, _points, userPoints[_user]);
    }

    /**
     * @dev Retrieves the points balance of a specific user.
     * @param _user The address of the user to query.
     * @return The total loyalty points of the user.
     */
    function getPoints(address _user) public view returns (uint256) {
        return userPoints[_user];
    }
}
