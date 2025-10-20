// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    address public owner;
    
    mapping(address => uint256) public points;
    
    // Events
    event PointsGranted(address indexed user, uint256 amount);
    event PointsDeducted(address indexed user, uint256 amount);
    event PointsTransferred(address indexed from, address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Grant points to a user
     * @param _user The address of the user
     * @param _amount The amount of points to grant
     */
    function grantPoints(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "Cannot grant points to zero address");
        require(_amount > 0, "Amount must be greater than 0");
        
        points[_user] += _amount;
        
        emit PointsGranted(_user, _amount);
    }
    
    /**
     * @dev Grant points to multiple users
     * @param _users Array of user addresses
     * @param _amounts Array of amounts corresponding to each user
     */
    function grantPointsBatch(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        require(_users.length == _amounts.length, "Arrays length mismatch");
        require(_users.length > 0, "Arrays cannot be empty");
        
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Cannot grant points to zero address");
            require(_amounts[i] > 0, "Amount must be greater than 0");
            
            points[_users[i]] += _amounts[i];
            emit PointsGranted(_users[i], _amounts[i]);
        }
    }
    
    /**
     * @dev Deduct points from a user
     * @param _user The address of the user
     * @param _amount The amount of points to deduct
     */
    function deductPoints(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "Cannot deduct points from zero address");
        require(_amount > 0, "Amount must be greater than 0");
        require(points[_user] >= _amount, "Insufficient points");
        
        points[_user] -= _amount;
        
        emit PointsDeducted(_user, _amount);
    }
    
    /**
     * @dev Transfer points from one user to another (by owner)
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _amount The amount of points to transfer
     */
    function transferPoints(address _from, address _to, uint256 _amount) external onlyOwner {
        require(_from != address(0), "Cannot transfer from zero address");
        require(_to != address(0), "Cannot transfer to zero address");
        require(_amount > 0, "Amount must be greater than 0");
        require(points[_from] >= _amount, "Insufficient points");
        
        points[_from] -= _amount;
        points[_to] += _amount;
        
        emit PointsTransferred(_from, _to, _amount);
    }
    
    /**
     * @dev Get the points balance of a user
     * @param _user The address of the user
     * @return The points balance
     */
    function getPoints(address _user) external view returns (uint256) {
        return points[_user];
    }
    
    /**
     * @dev Get the caller's points balance
     * @return The points balance
     */
    function myPoints() external view returns (uint256) {
        return points[msg.sender];
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
