// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikesTracker {
    mapping(address => uint256) public likesReceived;
    mapping(address => mapping(address => bool)) public liked;

    event Liked(address indexed from, address indexed to);

    function like(address user) external {
        require(user != msg.sender, "Cannot like yourself");
        require(!liked[msg.sender][user], "Already liked");
        liked[msg.sender][user] = true;
        likesReceived[user] += 1;
        emit Liked(msg.sender, user);
    }

    function getLikes(address user) external view returns (uint256) {
        return likesReceived[user];
    }
}
