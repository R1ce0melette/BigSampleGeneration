// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct User {
        int256 reputation;
        mapping(address => bool) hasVoted;
    }

    mapping(address => User) private users;

    event Voted(address indexed voter, address indexed target, int8 voteType, int256 newReputation);

    function vote(address target, bool isUpvote) external {
        require(target != msg.sender, "Cannot vote for yourself");
        require(!users[target].hasVoted[msg.sender], "Already voted for this user");

        users[target].hasVoted[msg.sender] = true;
        if (isUpvote) {
            users[target].reputation += 1;
            emit Voted(msg.sender, target, 1, users[target].reputation);
        } else {
            users[target].reputation -= 1;
            emit Voted(msg.sender, target, -1, users[target].reputation);
        }
    }

    function getReputation(address user) external view returns (int256) {
        return users[user].reputation;
    }
}
