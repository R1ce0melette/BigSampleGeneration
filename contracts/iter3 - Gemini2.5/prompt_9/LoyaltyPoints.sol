// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LoyaltyPoints
 * @dev A contract for a simple loyalty points system where the owner
 * can grant and deduct points from users.
 */
contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) public points;

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
     * @dev Grants loyalty points to a specific user.
     * Only the owner can call this function.
     * @param _user The address of the user to receive points.
     * @param _amount The number of points to grant.
     */
    function grantPoints(address _user, uint256 _amount) public onlyOwner {
        require(_user != address(0), "User address cannot be the zero address.");
        require(_amount > 0, "Amount must be greater than zero.");

        points[_user] += _amount;
        emit PointsGranted(_user, _amount);
    }

    /**
     * @dev Deducts loyalty points from a specific user.
     * Only the owner can call this function.
     * The user must have enough points to be deducted.
     * @param _user The address of the user to deduct points from.
     * @param _amount The number of points to deduct.
     */
    function deductPoints(address _user, uint256 _amount) public onlyOwner {
        require(_user != address(0), "User address cannot be the zero address.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(points[_user] >= _amount, "Insufficient points to deduct.");

        points[_user] -= _amount;
        emit PointsDeducted(_user, _amount);
    }

    /**
     * @dev Retrieves the loyalty points balance for a specific user.
     * @param _user The address of the user.
     * @return The total loyalty points of the user.
     */
    function getPoints(address _user) public view returns (uint256) {
        return points[_user];
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * Only the current owner can call this function.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        owner = newOwner;
    }
}
