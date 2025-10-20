// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct Reputation {
        int256 score;
    }

    mapping(address => Reputation) public reputations;
    mapping(address => mapping(address => bool)) public hasVoted;

    event Voted(address indexed voter, address indexed target, bool isUpvote);

    function vote(address _target, bool _isUpvote) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        require(!hasVoted[msg.sender][_target], "You have already voted for this user.");

        hasVoted[msg.sender][_target] = true;

        if (_isUpvote) {
            reputations[_target].score++;
        } else {
            reputations[_target].score--;
        }

        emit Voted(msg.sender, _target, _isUpvote);
    }

    function getReputation(address _user) public view returns (int256) {
        return reputations[_user].score;
    }
}
