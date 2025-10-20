// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikeTracker {
    mapping(address => uint256) public likes;
    mapping(address => mapping(address => bool)) public hasLiked;

    event Liked(address indexed liker, address indexed liked);

    function like(address _user) public {
        require(_user != msg.sender, "You cannot like yourself");
        require(!hasLiked[msg.sender][_user], "You have already liked this user");

        likes[_user]++;
        hasLiked[msg.sender][_user] = true;

        emit Liked(msg.sender, _user);
    }

    function getLikes(address _user) public view returns (uint256) {
        return likes[_user];
    }
}
