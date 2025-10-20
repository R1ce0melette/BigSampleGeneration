// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LikeTracker
 * @dev A contract that tracks the number of likes each address receives
 * Users can like other users only once
 */
contract LikeTracker {
    // Mapping to track total likes per address
    mapping(address => uint256) public likesReceived;
    
    // Mapping to track if an address has liked another address
    // liker => liked => hasLiked
    mapping(address => mapping(address => bool)) public hasLiked;
    
    // Events
    event Liked(address indexed liker, address indexed liked);
    event Unliked(address indexed unliker, address indexed unliked);
    
    /**
     * @dev Like another user's address
     * @param user The address to like
     * Requirements:
     * - Cannot like yourself
     * - Cannot like the same address more than once
     */
    function like(address user) external {
        require(user != address(0), "Cannot like zero address");
        require(user != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][user], "Already liked this user");
        
        hasLiked[msg.sender][user] = true;
        likesReceived[user]++;
        
        emit Liked(msg.sender, user);
    }
    
    /**
     * @dev Unlike a previously liked user
     * @param user The address to unlike
     * Requirements:
     * - Must have previously liked the user
     */
    function unlike(address user) external {
        require(hasLiked[msg.sender][user], "Have not liked this user");
        
        hasLiked[msg.sender][user] = false;
        likesReceived[user]--;
        
        emit Unliked(msg.sender, user);
    }
    
    /**
     * @dev Get the number of likes an address has received
     * @param user The address to query
     * @return The number of likes received
     */
    function getLikesReceived(address user) external view returns (uint256) {
        return likesReceived[user];
    }
    
    /**
     * @dev Check if the caller has liked a specific user
     * @param user The address to check
     * @return True if the caller has liked the user, false otherwise
     */
    function hasLikedUser(address user) external view returns (bool) {
        return hasLiked[msg.sender][user];
    }
    
    /**
     * @dev Check if one address has liked another address
     * @param liker The address that potentially gave the like
     * @param liked The address that potentially received the like
     * @return True if liker has liked the liked address, false otherwise
     */
    function checkIfLiked(address liker, address liked) external view returns (bool) {
        return hasLiked[liker][liked];
    }
    
    /**
     * @dev Get the number of likes the caller has received
     * @return The number of likes received by the caller
     */
    function getMyLikes() external view returns (uint256) {
        return likesReceived[msg.sender];
    }
}
