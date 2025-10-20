// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReputationSystem
 * @dev A contract for managing user reputations through upvotes and downvotes.
 */
contract ReputationSystem {

    struct Reputation {
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
    }

    mapping(address => Reputation) public reputations;
    mapping(address => mapping(address => int8)) public votes; // 1 for upvote, -1 for downvote

    event Voted(address indexed voter, address indexed target, int8 vote);

    /**
     * @dev Upvotes a user, increasing their reputation score.
     */
    function upvote(address _target) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        
        int8 currentVote = votes[msg.sender][_target];
        require(currentVote != 1, "You have already upvoted this user.");

        if (currentVote == -1) {
            reputations[_target].downvotes--;
        }
        
        reputations[_target].upvotes++;
        reputations[_target].score += (currentVote == -1) ? 2 : 1;
        votes[msg.sender][_target] = 1;

        emit Voted(msg.sender, _target, 1);
    }

    /**
     * @dev Downvotes a user, decreasing their reputation score.
     */
    function downvote(address _target) public {
        require(_target != msg.sender, "You cannot vote for yourself.");

        int8 currentVote = votes[msg.sender][_target];
        require(currentVote != -1, "You have already downvoted this user.");

        if (currentVote == 1) {
            reputations[_target].upvotes--;
        }

        reputations[_target].downvotes++;
        reputations[_target].score -= (currentVote == 1) ? 2 : 1;
        votes[msg.sender][_target] = -1;

        emit Voted(msg.sender, _target, -1);
    }

    /**
     * @dev Returns the reputation score of a user.
     */
    function getReputation(address _user) public view returns (int256) {
        return reputations[_user].score;
    }
}
