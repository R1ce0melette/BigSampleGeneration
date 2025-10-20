// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikeTracker {
    mapping(address => uint256) public likesReceived;
    mapping(address => mapping(address => bool)) public hasLiked;
    
    event Liked(address indexed liker, address indexed recipient);
    event Unliked(address indexed liker, address indexed recipient);
    
    function like(address _recipient) external {
        require(_recipient != address(0), "Cannot like zero address");
        require(_recipient != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][_recipient], "Already liked this address");
        
        hasLiked[msg.sender][_recipient] = true;
        likesReceived[_recipient]++;
        
        emit Liked(msg.sender, _recipient);
    }
    
    function unlike(address _recipient) external {
        require(_recipient != address(0), "Cannot unlike zero address");
        require(hasLiked[msg.sender][_recipient], "Haven't liked this address");
        
        hasLiked[msg.sender][_recipient] = false;
        likesReceived[_recipient]--;
        
        emit Unliked(msg.sender, _recipient);
    }
    
    function getLikesCount(address _user) external view returns (uint256) {
        return likesReceived[_user];
    }
    
    function hasUserLiked(address _liker, address _recipient) external view returns (bool) {
        return hasLiked[_liker][_recipient];
    }
}
