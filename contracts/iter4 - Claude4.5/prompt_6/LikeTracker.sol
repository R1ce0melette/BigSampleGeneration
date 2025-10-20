// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LikeTracker
 * @dev A contract that tracks the number of likes each address receives, with users able to like others once
 */
contract LikeTracker {
    // Mapping from address to their total like count
    mapping(address => uint256) public likeCount;
    
    // Mapping to track if user A has liked user B: liker => liked => bool
    mapping(address => mapping(address => bool)) public hasLiked;
    
    // Events
    event Liked(address indexed liker, address indexed liked);
    event Unliked(address indexed liker, address indexed liked);
    
    /**
     * @dev Allows a user to like another user's address
     * @param _user The address to like
     * Requirements:
     * - Cannot like yourself
     * - Cannot like the same address twice
     */
    function like(address _user) external {
        require(_user != address(0), "Cannot like zero address");
        require(_user != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][_user], "Already liked this address");
        
        hasLiked[msg.sender][_user] = true;
        likeCount[_user]++;
        
        emit Liked(msg.sender, _user);
    }
    
    /**
     * @dev Allows a user to unlike another user's address
     * @param _user The address to unlike
     * Requirements:
     * - Must have previously liked the address
     */
    function unlike(address _user) external {
        require(hasLiked[msg.sender][_user], "Have not liked this address");
        
        hasLiked[msg.sender][_user] = false;
        likeCount[_user]--;
        
        emit Unliked(msg.sender, _user);
    }
    
    /**
     * @dev Returns the number of likes an address has received
     * @param _user The address to query
     * @return The number of likes
     */
    function getLikeCount(address _user) external view returns (uint256) {
        return likeCount[_user];
    }
    
    /**
     * @dev Returns the number of likes the caller has received
     * @return The number of likes
     */
    function getMyLikes() external view returns (uint256) {
        return likeCount[msg.sender];
    }
    
    /**
     * @dev Checks if the caller has liked a specific address
     * @param _user The address to check
     * @return True if the caller has liked the address, false otherwise
     */
    function haveILiked(address _user) external view returns (bool) {
        return hasLiked[msg.sender][_user];
    }
    
    /**
     * @dev Checks if one address has liked another
     * @param _liker The address of the liker
     * @param _liked The address of the liked user
     * @return True if _liker has liked _liked, false otherwise
     */
    function hasUserLiked(address _liker, address _liked) external view returns (bool) {
        return hasLiked[_liker][_liked];
    }
}
