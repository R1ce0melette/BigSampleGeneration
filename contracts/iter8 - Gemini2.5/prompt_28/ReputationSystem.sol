// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReputationSystem
 * @dev A contract that allows users to manage reputation by upvoting and downvoting others.
 * Each user can only vote once per target address.
 */
contract ReputationSystem {
    struct Reputation {
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
    }

    // Mapping from a user's address to their reputation details
    mapping(address => Reputation) public reputations;

    // Mapping to track who has voted for whom: voter => target => vote type (1 for up, -1 for down)
    mapping(address => mapping(address => int8)) public votes;

    event Voted(address indexed voter, address indexed target, int8 voteType, int256 newScore);

    /**
     * @dev Upvotes a target user. A user cannot upvote someone they have already voted for.
     * If they previously downvoted, the downvote is removed and an upvote is cast.
     * @param _target The address of the user to upvote.
     */
    function upvote(address _target) external {
        require(_target != msg.sender, "You cannot vote for yourself.");
        
        int8 currentVote = votes[msg.sender][_target];
        require(currentVote != 1, "You have already upvoted this user.");

        Reputation storage targetRep = reputations[_target];

        if (currentVote == -1) {
            // User is changing their vote from down to up
            targetRep.downvotes--;
        }
        
        targetRep.upvotes++;
        targetRep.score = int256(targetRep.upvotes) - int256(targetRep.downvotes);
        votes[msg.sender][_target] = 1;

        emit Voted(msg.sender, _target, 1, targetRep.score);
    }

    /**
     * @dev Downvotes a target user. A user cannot downvote someone they have already voted for.
     * If they previously upvoted, the upvote is removed and a downvote is cast.
     * @param _target The address of the user to downvote.
     */
    function downvote(address _target) external {
        require(_target != msg.sender, "You cannot vote for yourself.");

        int8 currentVote = votes[msg.sender][_target];
        require(currentVote != -1, "You have already downvoted this user.");

        Reputation storage targetRep = reputations[_target];

        if (currentVote == 1) {
            // User is changing their vote from up to down
            targetRep.upvotes--;
        }

        targetRep.downvotes++;
        targetRep.score = int256(targetRep.upvotes) - int256(targetRep.downvotes);
        votes[msg.sender][_target] = -1;

        emit Voted(msg.sender, _target, -1, targetRep.score);
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address _user) external view returns (int256) {
        return reputations[_user].score;
    }

    /**
     * @dev Retrieves the detailed vote counts for a user.
     * @param _user The address of the user.
     * @return The number of upvotes and downvotes.
     */
    function getVoteCounts(address _user) external view returns (uint256, uint256) {
        Reputation storage rep = reputations[_user];
        return (rep.upvotes, rep.downvotes);
    }
}
