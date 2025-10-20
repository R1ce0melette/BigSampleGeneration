// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikeTracker {
    mapping(address => uint256) public likeCount;
    mapping(address => mapping(address => bool)) public hasLiked;

    event Liked(address indexed liker, address indexed liked);
    event Unliked(address indexed liker, address indexed unliked);

    function likeUser(address user) external {
        require(user != address(0), "Cannot like zero address");
        require(user != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][user], "Already liked this user");

        hasLiked[msg.sender][user] = true;
        likeCount[user]++;

        emit Liked(msg.sender, user);
    }

    function unlikeUser(address user) external {
        require(user != address(0), "Cannot unlike zero address");
        require(hasLiked[msg.sender][user], "Have not liked this user");

        hasLiked[msg.sender][user] = false;
        likeCount[user]--;

        emit Unliked(msg.sender, user);
    }

    function getLikeCount(address user) external view returns (uint256) {
        return likeCount[user];
    }

    function hasUserLiked(address liker, address liked) external view returns (bool) {
        return hasLiked[liker][liked];
    }
}
