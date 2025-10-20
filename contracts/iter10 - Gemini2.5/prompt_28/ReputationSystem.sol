// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct UserReputation {
        int256 score;
    }

    mapping(address => UserReputation) public reputations;
    mapping(address => mapping(address => int8)) public votes; // 1 for upvote, -1 for downvote, 0 for no vote

    event Voted(address indexed voter, address indexed target, int8 vote);

    function vote(address _target, bool _upvote) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        
        int8 currentVote = votes[msg.sender][_target];
        int8 newVote = _upvote ? 1 : -1;

        // If user is changing their vote
        if (currentVote != 0) {
            reputations[_target].score -= currentVote;
        }

        // If user is casting a new vote or changing vote
        if (currentVote != newVote) {
            reputations[_target].score += newVote;
            votes[msg.sender][_target] = newVote;
        } else { // If user is removing their vote
            delete votes[msg.sender][_target];
        }

        emit Voted(msg.sender, _target, newVote);
    }

    function getReputation(address _user) public view returns (int256) {
        return reputations[_user].score;
    }
}
