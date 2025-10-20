// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LoyaltyPoints
 * @dev A loyalty points system where the owner can grant and deduct points from users
 */
contract LoyaltyPoints {
    address public owner;
    
    // Mapping to track points balance for each user
    mapping(address => uint256) public pointsBalance;
    
    // Mapping to track total points earned by each user
    mapping(address => uint256) public totalPointsEarned;
    
    // Mapping to track total points spent by each user
    mapping(address => uint256) public totalPointsSpent;
    
    // Events
    event PointsGranted(address indexed user, uint256 amount, string reason);
    event PointsDeducted(address indexed user, uint256 amount, string reason);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Grants points to a user
     * @param _user The address of the user
     * @param _amount The amount of points to grant
     * @param _reason The reason for granting points
     */
    function grantPoints(address _user, uint256 _amount, string memory _reason) external onlyOwner {
        require(_user != address(0), "Cannot grant points to zero address");
        require(_amount > 0, "Amount must be greater than 0");
        
        pointsBalance[_user] += _amount;
        totalPointsEarned[_user] += _amount;
        
        emit PointsGranted(_user, _amount, _reason);
    }
    
    /**
     * @dev Grants points to multiple users at once
     * @param _users Array of user addresses
     * @param _amounts Array of point amounts
     * @param _reason The reason for granting points
     */
    function grantPointsBatch(
        address[] memory _users,
        uint256[] memory _amounts,
        string memory _reason
    ) external onlyOwner {
        require(_users.length == _amounts.length, "Arrays length mismatch");
        require(_users.length > 0, "Arrays cannot be empty");
        
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Cannot grant points to zero address");
            require(_amounts[i] > 0, "Amount must be greater than 0");
            
            pointsBalance[_users[i]] += _amounts[i];
            totalPointsEarned[_users[i]] += _amounts[i];
            
            emit PointsGranted(_users[i], _amounts[i], _reason);
        }
    }
    
    /**
     * @dev Deducts points from a user
     * @param _user The address of the user
     * @param _amount The amount of points to deduct
     * @param _reason The reason for deducting points
     */
    function deductPoints(address _user, uint256 _amount, string memory _reason) external onlyOwner {
        require(_user != address(0), "Cannot deduct points from zero address");
        require(_amount > 0, "Amount must be greater than 0");
        require(pointsBalance[_user] >= _amount, "Insufficient points balance");
        
        pointsBalance[_user] -= _amount;
        totalPointsSpent[_user] += _amount;
        
        emit PointsDeducted(_user, _amount, _reason);
    }
    
    /**
     * @dev Returns the points balance of a specific user
     * @param _user The address of the user
     * @return The points balance
     */
    function getPointsBalance(address _user) external view returns (uint256) {
        return pointsBalance[_user];
    }
    
    /**
     * @dev Returns the points balance of the caller
     * @return The points balance
     */
    function getMyPoints() external view returns (uint256) {
        return pointsBalance[msg.sender];
    }
    
    /**
     * @dev Returns the total points earned by a user
     * @param _user The address of the user
     * @return The total points earned
     */
    function getTotalPointsEarned(address _user) external view returns (uint256) {
        return totalPointsEarned[_user];
    }
    
    /**
     * @dev Returns the total points spent by a user
     * @param _user The address of the user
     * @return The total points spent
     */
    function getTotalPointsSpent(address _user) external view returns (uint256) {
        return totalPointsSpent[_user];
    }
    
    /**
     * @dev Returns comprehensive points information for a user
     * @param _user The address of the user
     * @return balance Current points balance
     * @return earned Total points earned
     * @return spent Total points spent
     */
    function getUserPointsInfo(address _user) external view returns (
        uint256 balance,
        uint256 earned,
        uint256 spent
    ) {
        return (
            pointsBalance[_user],
            totalPointsEarned[_user],
            totalPointsSpent[_user]
        );
    }
    
    /**
     * @dev Transfers ownership of the contract to a new owner
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different from current owner");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
