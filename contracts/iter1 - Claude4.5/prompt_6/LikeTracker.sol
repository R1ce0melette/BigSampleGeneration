// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LikeTracker
 * @dev A contract that tracks the number of likes each address receives
 * Users can like other users only once
 */
contract LikeTracker {
    // Mapping to track total likes for each address
    mapping(address => uint256) public likeCounts;
    
    // Mapping to track who has liked whom: liker => liked => hasLiked
    mapping(address => mapping(address => bool)) public hasLiked;
    
    // Mapping to track all addresses that liked a specific user
    mapping(address => address[]) private likers;
    
    // Mapping to track all addresses that a user has liked
    mapping(address => address[]) private likedByUser;
    
    event UserLiked(address indexed liker, address indexed liked);
    event UserUnliked(address indexed unliker, address indexed unliked);
    
    /**
     * @dev Like another user
     * @param user The address to like
     */
    function likeUser(address user) external {
        require(user != address(0), "Cannot like zero address");
        require(user != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][user], "Already liked this user");
        
        hasLiked[msg.sender][user] = true;
        likeCounts[user]++;
        likers[user].push(msg.sender);
        likedByUser[msg.sender].push(user);
        
        emit UserLiked(msg.sender, user);
    }
    
    /**
     * @dev Unlike a user (remove a like)
     * @param user The address to unlike
     */
    function unlikeUser(address user) external {
        require(hasLiked[msg.sender][user], "Haven't liked this user");
        
        hasLiked[msg.sender][user] = false;
        likeCounts[user]--;
        
        // Remove from likers array
        _removeFromArray(likers[user], msg.sender);
        
        // Remove from likedByUser array
        _removeFromArray(likedByUser[msg.sender], user);
        
        emit UserUnliked(msg.sender, user);
    }
    
    /**
     * @dev Get the number of likes for a user
     * @param user The address to query
     * @return The number of likes
     */
    function getLikeCount(address user) external view returns (uint256) {
        return likeCounts[user];
    }
    
    /**
     * @dev Check if one user has liked another
     * @param liker The address of the liker
     * @param liked The address of the liked user
     * @return Whether liker has liked the user
     */
    function checkIfLiked(address liker, address liked) external view returns (bool) {
        return hasLiked[liker][liked];
    }
    
    /**
     * @dev Get all addresses that have liked a specific user
     * @param user The address to query
     * @return Array of addresses that liked the user
     */
    function getLikers(address user) external view returns (address[] memory) {
        return likers[user];
    }
    
    /**
     * @dev Get all addresses that a user has liked
     * @param user The address to query
     * @return Array of addresses that the user has liked
     */
    function getLikedUsers(address user) external view returns (address[] memory) {
        return likedByUser[user];
    }
    
    /**
     * @dev Get the number of users that a specific user has liked
     * @param user The address to query
     * @return The count of users liked by the specified user
     */
    function getLikedCount(address user) external view returns (uint256) {
        return likedByUser[user].length;
    }
    
    /**
     * @dev Internal function to remove an address from an array
     * @param array The array to modify
     * @param addressToRemove The address to remove
     */
    function _removeFromArray(address[] storage array, address addressToRemove) private {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == addressToRemove) {
                // Move the last element to this position and pop
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }
}
