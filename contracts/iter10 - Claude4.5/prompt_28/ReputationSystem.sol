// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct User {
        uint256 upvotes;
        uint256 downvotes;
        int256 reputationScore;
        bool exists;
    }

    struct Vote {
        address voter;
        address target;
        bool isUpvote;
        uint256 timestamp;
        string comment;
    }

    mapping(address => User) public users;
    mapping(address => mapping(address => bool)) public hasVoted;
    mapping(address => mapping(address => bool)) public lastVoteWasUpvote;
    
    Vote[] public votes;
    mapping(address => uint256[]) public votesReceived;
    mapping(address => uint256[]) public votesGiven;

    event UserRegistered(address indexed user);
    event Upvoted(address indexed voter, address indexed target, uint256 timestamp);
    event Downvoted(address indexed voter, address indexed target, uint256 timestamp);
    event VoteChanged(address indexed voter, address indexed target, bool isUpvote, uint256 timestamp);

    function registerUser() external {
        require(!users[msg.sender].exists, "User already registered");
        
        users[msg.sender] = User({
            upvotes: 0,
            downvotes: 0,
            reputationScore: 0,
            exists: true
        });

        emit UserRegistered(msg.sender);
    }

    function upvote(address target, string memory comment) external {
        require(target != address(0), "Invalid target address");
        require(target != msg.sender, "Cannot vote for yourself");
        
        if (!users[msg.sender].exists) {
            _registerUser(msg.sender);
        }
        
        if (!users[target].exists) {
            _registerUser(target);
        }

        if (hasVoted[msg.sender][target]) {
            // If already voted, check if changing vote
            if (!lastVoteWasUpvote[msg.sender][target]) {
                // Changing from downvote to upvote
                users[target].downvotes--;
                users[target].upvotes++;
                users[target].reputationScore += 2; // +1 to remove downvote, +1 for upvote
                lastVoteWasUpvote[msg.sender][target] = true;
                
                emit VoteChanged(msg.sender, target, true, block.timestamp);
            }
            // If already upvoted, do nothing
            return;
        }

        hasVoted[msg.sender][target] = true;
        lastVoteWasUpvote[msg.sender][target] = true;
        users[target].upvotes++;
        users[target].reputationScore++;

        votes.push(Vote({
            voter: msg.sender,
            target: target,
            isUpvote: true,
            timestamp: block.timestamp,
            comment: comment
        }));

        uint256 voteIndex = votes.length - 1;
        votesReceived[target].push(voteIndex);
        votesGiven[msg.sender].push(voteIndex);

        emit Upvoted(msg.sender, target, block.timestamp);
    }

    function downvote(address target, string memory comment) external {
        require(target != address(0), "Invalid target address");
        require(target != msg.sender, "Cannot vote for yourself");
        
        if (!users[msg.sender].exists) {
            _registerUser(msg.sender);
        }
        
        if (!users[target].exists) {
            _registerUser(target);
        }

        if (hasVoted[msg.sender][target]) {
            // If already voted, check if changing vote
            if (lastVoteWasUpvote[msg.sender][target]) {
                // Changing from upvote to downvote
                users[target].upvotes--;
                users[target].downvotes++;
                users[target].reputationScore -= 2; // -1 to remove upvote, -1 for downvote
                lastVoteWasUpvote[msg.sender][target] = false;
                
                emit VoteChanged(msg.sender, target, false, block.timestamp);
            }
            // If already downvoted, do nothing
            return;
        }

        hasVoted[msg.sender][target] = true;
        lastVoteWasUpvote[msg.sender][target] = false;
        users[target].downvotes++;
        users[target].reputationScore--;

        votes.push(Vote({
            voter: msg.sender,
            target: target,
            isUpvote: false,
            timestamp: block.timestamp,
            comment: comment
        }));

        uint256 voteIndex = votes.length - 1;
        votesReceived[target].push(voteIndex);
        votesGiven[msg.sender].push(voteIndex);

        emit Downvoted(msg.sender, target, block.timestamp);
    }

    function removeVote(address target) external {
        require(hasVoted[msg.sender][target], "No vote to remove");

        if (lastVoteWasUpvote[msg.sender][target]) {
            users[target].upvotes--;
            users[target].reputationScore--;
        } else {
            users[target].downvotes--;
            users[target].reputationScore++;
        }

        hasVoted[msg.sender][target] = false;
        delete lastVoteWasUpvote[msg.sender][target];
    }

    function _registerUser(address user) private {
        users[user] = User({
            upvotes: 0,
            downvotes: 0,
            reputationScore: 0,
            exists: true
        });

        emit UserRegistered(user);
    }

    function getReputation(address user) external view returns (
        uint256 upvotes,
        uint256 downvotes,
        int256 reputationScore
    ) {
        User memory userData = users[user];
        return (userData.upvotes, userData.downvotes, userData.reputationScore);
    }

    function hasUserVoted(address voter, address target) external view returns (bool) {
        return hasVoted[voter][target];
    }

    function getVoteType(address voter, address target) external view returns (bool isUpvote, bool hasVote) {
        if (!hasVoted[voter][target]) {
            return (false, false);
        }
        return (lastVoteWasUpvote[voter][target], true);
    }

    function getVotesReceived(address user) external view returns (uint256[] memory) {
        return votesReceived[user];
    }

    function getVotesGiven(address user) external view returns (uint256[] memory) {
        return votesGiven[user];
    }

    function getVote(uint256 voteIndex) external view returns (
        address voter,
        address target,
        bool isUpvote,
        uint256 timestamp,
        string memory comment
    ) {
        require(voteIndex < votes.length, "Vote does not exist");
        Vote memory vote = votes[voteIndex];
        return (vote.voter, vote.target, vote.isUpvote, vote.timestamp, vote.comment);
    }

    function getTotalVotes() external view returns (uint256) {
        return votes.length;
    }

    function getReputationRank(address user) external view returns (string memory) {
        int256 score = users[user].reputationScore;
        
        if (score >= 100) return "Excellent";
        if (score >= 50) return "Very Good";
        if (score >= 20) return "Good";
        if (score >= 0) return "Neutral";
        if (score >= -20) return "Poor";
        if (score >= -50) return "Very Poor";
        return "Critical";
    }
}
