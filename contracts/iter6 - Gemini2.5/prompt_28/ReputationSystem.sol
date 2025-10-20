// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    // Reputation score for each user
    mapping(address => int256) public reputations;

    // Tracks who has voted on whom to prevent double voting
    // voter => target => vote type (1 for upvote, -1 for downvote)
    mapping(address => mapping(address => int8)) public votes;

    event Voted(address indexed voter, address indexed target, int8 voteType);

    function vote(address _target, bool _upvote) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        
        int8 existingVote = votes[msg.sender][_target];
        require(existingVote == 0, "You have already voted for this user.");

        int8 voteType = _upvote ? 1 : -1;

        // Update reputation score
        reputations[_target] += voteType;

        // Record the vote
        votes[msg.sender][_target] = voteType;

        emit Voted(msg.sender, _target, voteType);
    }

    function getReputation(address _user) public view returns (int256) {
        return reputations[_user];
    }

    function getVote(address _voter, address _target) public view returns (int8) {
        return votes[_voter][_target];
    }
}
