// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct Reputation {
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
    }

    // Mapping from a user's address to their reputation details
    mapping(address => Reputation) public reputations;
    // Mapping to prevent users from voting multiple times for the same person
    // voter => target => hasVoted (true if upvoted, could be extended for downvotes)
    mapping(address => mapping(address => bool)) public hasVoted;

    event Voted(address indexed voter, address indexed target, bool isUpvote);

    /**
     * @dev Allows a user to upvote another user.
     * @param _target The address of the user to be upvoted.
     */
    function upvote(address _target) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        require(!hasVoted[msg.sender][_target], "You have already voted for this user.");

        reputations[_target].score++;
        reputations[_target].upvotes++;
        hasVoted[msg.sender][_target] = true;

        emit Voted(msg.sender, _target, true);
    }

    /**
     * @dev Allows a user to downvote another user.
     * @param _target The address of the user to be downvoted.
     */
    function downvote(address _target) public {
        require(_target != msg.sender, "You cannot vote for yourself.");
        require(!hasVoted[msg.sender][_target], "You have already voted for this user.");

        reputations[_target].score--;
        reputations[_target].downvotes++;
        hasVoted[msg.sender][_target] = true;

        emit Voted(msg.sender, _target, false);
    }

    /**
     * @dev Retrieves the reputation score and vote counts for a specific user.
     * @param _user The address of the user.
     * @return The reputation score, total upvotes, and total downvotes.
     */
    function getReputation(address _user) public view returns (int256, uint256, uint256) {
        Reputation storage rep = reputations[_user];
        return (rep.score, rep.upvotes, rep.downvotes);
    }
}
