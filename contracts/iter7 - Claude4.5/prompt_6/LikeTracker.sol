// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LikeTracker
 * @dev A contract that tracks the number of likes each address receives
 * Users can like other users only once
 */
contract LikeTracker {
    // Mapping to track total likes received by each address
    mapping(address => uint256) public likesReceived;
    
    // Mapping to track if an address has liked another address
    // liker => liked => hasLiked
    mapping(address => mapping(address => bool)) public hasLiked;
    
    // Events
    event Liked(address indexed liker, address indexed liked);
    event Unliked(address indexed liker, address indexed unliked);
    
    /**
     * @dev Like another user
     * @param user The address to like
     * Requirements:
     * - Cannot like yourself
     * - Cannot like the same user twice
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
     * @dev Unlike a user (remove a previously given like)
     * @param user The address to unlike
     * Requirements:
     * - Must have previously liked this user
     */
    function unlike(address user) external {
        require(hasLiked[msg.sender][user], "Have not liked this user");
        
        hasLiked[msg.sender][user] = false;
        likesReceived[user]--;
        
        emit Unliked(msg.sender, user);
    }
    
    /**
     * @dev Get the number of likes received by an address
     * @param user The address to query
     * @return The number of likes received
     */
    function getLikes(address user) external view returns (uint256) {
        return likesReceived[user];
    }
    
    /**
     * @dev Check if one address has liked another
     * @param liker The address that may have liked
     * @param liked The address that may have been liked
     * @return True if liker has liked the other address, false otherwise
     */
    function checkIfLiked(address liker, address liked) external view returns (bool) {
        return hasLiked[liker][liked];
    }
    
    /**
     * @dev Get the number of likes received by the caller
     * @return The number of likes received by msg.sender
     */
    function getMyLikes() external view returns (uint256) {
        return likesReceived[msg.sender];
    }
    
    /**
     * @dev Check if the caller has liked a specific user
     * @param user The address to check
     * @return True if caller has liked the user, false otherwise
     */
    function haveILiked(address user) external view returns (bool) {
        return hasLiked[msg.sender][user];
    }
}
