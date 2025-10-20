// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    
    mapping(address => uint256) public points;
    
    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);
    event PointsTransferred(address indexed from, address indexed to, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function grantPoints(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "Cannot grant points to zero address");
        require(_amount > 0, "Amount must be greater than zero");
        
        points[_user] += _amount;
        
        emit PointsGranted(_user, _amount);
    }
    
    function deductPoints(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "Cannot deduct points from zero address");
        require(_amount > 0, "Amount must be greater than zero");
        require(points[_user] >= _amount, "Insufficient points");
        
        points[_user] -= _amount;
        
        emit PointsDeducted(_user, _amount);
    }
    
    function transferPoints(address _to, uint256 _amount) external {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_to != msg.sender, "Cannot transfer to yourself");
        require(_amount > 0, "Amount must be greater than zero");
        require(points[msg.sender] >= _amount, "Insufficient points");
        
        points[msg.sender] -= _amount;
        points[_to] += _amount;
        
        emit PointsTransferred(msg.sender, _to, _amount);
    }
    
    function getPoints(address _user) external view returns (uint256) {
        return points[_user];
    }
    
    function getMyPoints() external view returns (uint256) {
        return points[msg.sender];
    }
}
