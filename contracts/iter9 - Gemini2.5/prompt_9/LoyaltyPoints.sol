// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) public points;

    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Grants loyalty points to a user.
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
     * @dev Deducts loyalty points from a user.
     * @param _user The address of the user to deduct points from.
     * @param _amount The number of points to deduct.
     */
    function deductPoints(address _user, uint256 _amount) public onlyOwner {
        require(_user != address(0), "User address cannot be the zero address.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(points[_user] >= _amount, "Insufficient points.");

        points[_user] -= _amount;
        emit PointsDeducted(_user, _amount);
    }

    /**
     * @dev Retrieves the loyalty points balance for a specific user.
     * @param _user The address of the user.
     * @return The total number of loyalty points.
     */
    function getPoints(address _user) public view returns (uint256) {
        return points[_user];
    }
}
