// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) public points;

    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function grantPoints(address _user, uint256 _amount) public onlyOwner {
        require(_user != address(0), "Cannot grant points to the zero address.");
        points[_user] += _amount;
        emit PointsGranted(_user, _amount);
    }

    function deductPoints(address _user, uint256 _amount) public onlyOwner {
        require(points[_user] >= _amount, "Not enough points to deduct.");
        points[_user] -= _amount;
        emit PointsDeducted(_user, _amount);
    }

    function getPoints(address _user) public view returns (uint256) {
        return points[_user];
    }
}
