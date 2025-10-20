// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReputationSystem
 * @dev A contract for a simple reputation system where users can upvote or
 * downvote other addresses. Each user can only vote once per address.
 */
contract ReputationSystem {
    struct Reputation {
        int256 score;
    }

    // Mapping from a user's address to their reputation score
    mapping(address => Reputation) public reputations;
    // Mapping to track votes: voter => (votedOn => voteType)
    // voteType: 1 for upvote, -1 for downvote, 0 for no vote
    mapping(address => mapping(address => int8)) public votes;

    /**
     * @dev Emitted when a user's reputation is changed.
     * @param user The address whose reputation was changed.
     * @param voter The address of the user who cast the vote.
     * @param newScore The new reputation score of the user.
     */
    event ReputationChanged(address indexed user, address indexed voter, int256 newScore);

    /**
     * @dev Allows the sender to upvote another user.
     * A user cannot vote for themselves.
     * A user can change their vote from downvote to upvote, but cannot upvote twice.
     * @param _user The address of the user to upvote.
     */
    function upvote(address _user) public {
        require(_user != msg.sender, "You cannot vote for yourself.");
        
        int8 currentVote = votes[msg.sender][_user];
        require(currentVote != 1, "You have already upvoted this user.");

        if (currentVote == -1) {
            // User is changing their vote from downvote to upvote
            reputations[_user].score += 2;
        } else {
            // New upvote
            reputations[_user].score += 1;
        }

        votes[msg.sender][_user] = 1;
        emit ReputationChanged(_user, msg.sender, reputations[_user].score);
    }

    /**
     * @dev Allows the sender to downvote another user.
     * A user cannot vote for themselves.
     * A user can change their vote from upvote to downvote, but cannot downvote twice.
     * @param _user The address of the user to downvote.
     */
    function downvote(address _user) public {
        require(_user != msg.sender, "You cannot vote for yourself.");

        int8 currentVote = votes[msg.sender][_user];
        require(currentVote != -1, "You have already downvoted this user.");

        if (currentVote == 1) {
            // User is changing their vote from upvote to downvote
            reputations[_user].score -= 2;
        } else {
            // New downvote
            reputations[_user].score -= 1;
        }

        votes[msg.sender][_user] = -1;
        emit ReputationChanged(_user, msg.sender, reputations[_user].score);
    }

    /**
     * @dev Retrieves the reputation score for a specific user.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getReputation(address _user) public view returns (int256) {
        return reputations[_user].score;
    }

    /**
     * @dev Checks the vote that one user has cast on another.
     * @param _voter The address of the voter.
     * @param _votedOn The address of the user who was voted on.
     * @return 1 for an upvote, -1 for a downvote, 0 for no vote.
     */
    function getVote(address _voter, address _votedOn) public view returns (int8) {
        return votes[_voter][_votedOn];
    }
}
