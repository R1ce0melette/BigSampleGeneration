// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikeTracker {
    mapping(address => uint256) public likeCount;
    mapping(address => mapping(address => bool)) public hasLiked;
    
    event LikeGiven(address indexed liker, address indexed recipient);
    event LikeRemoved(address indexed liker, address indexed recipient);
    
    function likeUser(address recipient) external {
        require(recipient != address(0), "Cannot like zero address");
        require(recipient != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][recipient], "Already liked this user");
        
        hasLiked[msg.sender][recipient] = true;
        likeCount[recipient]++;
        
        emit LikeGiven(msg.sender, recipient);
    }
    
    function unlikeUser(address recipient) external {
        require(hasLiked[msg.sender][recipient], "You haven't liked this user");
        
        hasLiked[msg.sender][recipient] = false;
        likeCount[recipient]--;
        
        emit LikeRemoved(msg.sender, recipient);
    }
    
    function getLikeCount(address user) external view returns (uint256) {
        return likeCount[user];
    }
    
    function hasUserLiked(address liker, address recipient) external view returns (bool) {
        return hasLiked[liker][recipient];
    }
}
