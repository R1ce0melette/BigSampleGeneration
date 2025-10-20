// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReputationSystem
 * @dev A contract for a simple reputation system where users can upvote or downvote others.
 * A user cannot vote for themselves and can only vote once per target user.
 */
contract ReputationSystem {
    // Struct to store the reputation score of a user.
    struct Reputation {
        int256 score; // Using a signed integer to allow for negative scores.
    }

    // Mapping from a user's address to their reputation data.
    mapping(address => Reputation) public reputations;

    // Mapping to track votes to prevent duplicate voting.
    // voter => target => vote type (1 for upvote, -1 for downvote)
    mapping(address => mapping(address => int8)) public votes;

    /**
     * @dev Emitted when a user's reputation is changed.
     * @param user The address of the user whose reputation was changed.
     * @param newScore The new reputation score of the user.
     */
    event ReputationChanged(address indexed user, int256 newScore);

    /**
     * @dev Allows the caller to upvote another user.
     * @param _target The address of the user to upvote.
     */
    function upvote(address _target) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        require(votes[msg.sender][_target] == 0, "You have already voted for this user.");

        votes[msg.sender][_target] = 1; // Mark as upvoted
        reputations[_target].score++;

        emit ReputationChanged(_target, reputations[_target].score);
    }

    /**
     * @dev Allows the caller to downvote another user.
     * @param _target The address of the user to downvote.
     */
    function downvote(address _target) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        require(votes[msg.sender][_target] == 0, "You have already voted for this user.");

        votes[msg.sender][_target] = -1; // Mark as downvoted
        reputations[_target].score--;

        emit ReputationChanged(_target, reputations[_target].score);
    }

    /**
     * @dev Retrieves the reputation score of a given user.
     * @param _user The address of the user to query.
     * @return The reputation score of the user.
     */
    function getReputation(address _user) public view returns (int256) {
        return reputations[_user].score;
    }

    /**
     * @dev Checks the vote cast by a specific voter on a target.
     * @param _voter The address of the voter.
     * @param _target The address of the target user.
     * @return 1 for an upvote, -1 for a downvote, 0 if no vote was cast.
     */
    function getVote(address _voter, address _target) public view returns (int8) {
        return votes[_voter][_target];
    }
}
