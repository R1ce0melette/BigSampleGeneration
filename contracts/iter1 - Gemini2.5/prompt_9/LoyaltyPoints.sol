// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    mapping(address => uint256) public points;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function grantPoints(address _user, uint256 _points) public onlyOwner {
        points[_user] += _points;
    }

    function deductPoints(address _user, uint256 _points) public onlyOwner {
        require(points[_user] >= _points, "Not enough points.");
        points[_user] -= _points;
    }

    function getPoints(address _user) public view returns (uint256) {
        return points[_user];
    }
}
