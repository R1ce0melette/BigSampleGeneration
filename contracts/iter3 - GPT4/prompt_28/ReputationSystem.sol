// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    mapping(address => int256) public reputation;
    mapping(address => mapping(address => bool)) public hasVoted;

    event Upvoted(address indexed from, address indexed to);
    event Downvoted(address indexed from, address indexed to);

    function upvote(address user) external {
        require(user != msg.sender, "Cannot upvote yourself");
        require(!hasVoted[msg.sender][user], "Already voted");
        hasVoted[msg.sender][user] = true;
        reputation[user] += 1;
        emit Upvoted(msg.sender, user);
    }

    function downvote(address user) external {
        require(user != msg.sender, "Cannot downvote yourself");
        require(!hasVoted[msg.sender][user], "Already voted");
        hasVoted[msg.sender][user] = true;
        reputation[user] -= 1;
        emit Downvoted(msg.sender, user);
    }

    function getReputation(address user) external view returns (int256) {
        return reputation[user];
    }
}
