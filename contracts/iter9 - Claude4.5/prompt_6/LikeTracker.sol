// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikeTracker {
    // Mapping from user address to total likes received
    mapping(address => uint256) public likesReceived;
    
    // Mapping to track if user A has liked user B: liker => liked => bool
    mapping(address => mapping(address => bool)) public hasLiked;
    
    // Events
    event Liked(address indexed liker, address indexed liked);
    event Unliked(address indexed liker, address indexed liked);
    
    /**
     * @dev Like another user
     * @param _user The address of the user to like
     */
    function likeUser(address _user) external {
        require(_user != address(0), "Cannot like zero address");
        require(_user != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][_user], "Already liked this user");
        
        hasLiked[msg.sender][_user] = true;
        likesReceived[_user]++;
        
        emit Liked(msg.sender, _user);
    }
    
    /**
     * @dev Unlike a user (remove a previous like)
     * @param _user The address of the user to unlike
     */
    function unlikeUser(address _user) external {
        require(_user != address(0), "Cannot unlike zero address");
        require(hasLiked[msg.sender][_user], "Have not liked this user");
        
        hasLiked[msg.sender][_user] = false;
        likesReceived[_user]--;
        
        emit Unliked(msg.sender, _user);
    }
    
    /**
     * @dev Get the total number of likes a user has received
     * @param _user The address of the user
     * @return The total number of likes received
     */
    function getLikesCount(address _user) external view returns (uint256) {
        return likesReceived[_user];
    }
    
    /**
     * @dev Check if one user has liked another
     * @param _liker The address of the liker
     * @param _liked The address of the liked user
     * @return True if the liker has liked the user, false otherwise
     */
    function checkIfLiked(address _liker, address _liked) external view returns (bool) {
        return hasLiked[_liker][_liked];
    }
    
    /**
     * @dev Get like status for caller toward a specific user
     * @param _user The address to check
     * @return True if caller has liked this user, false otherwise
     */
    function myLikeStatus(address _user) external view returns (bool) {
        return hasLiked[msg.sender][_user];
    }
}
