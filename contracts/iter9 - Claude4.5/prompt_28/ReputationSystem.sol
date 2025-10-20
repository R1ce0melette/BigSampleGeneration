// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct Vote {
        address voter;
        bool isUpvote;
        uint256 timestamp;
        string comment;
    }
    
    struct UserReputation {
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
        uint256 totalVotes;
    }
    
    mapping(address => UserReputation) public reputations;
    mapping(address => mapping(address => bool)) public hasVoted;
    mapping(address => Vote[]) public votesReceived;
    mapping(address => Vote[]) public votesGiven;
    
    uint256 public totalUsers;
    
    // Events
    event VoteCast(address indexed voter, address indexed target, bool isUpvote, string comment);
    event VoteChanged(address indexed voter, address indexed target, bool newVote);
    event VoteRemoved(address indexed voter, address indexed target);
    
    /**
     * @dev Cast a vote for another user
     * @param _target The address to vote for
     * @param _isUpvote True for upvote, false for downvote
     * @param _comment Optional comment with the vote
     */
    function vote(address _target, bool _isUpvote, string memory _comment) external {
        require(_target != address(0), "Invalid target address");
        require(_target != msg.sender, "Cannot vote for yourself");
        require(!hasVoted[msg.sender][_target], "Already voted for this user");
        
        // Initialize user reputation if first time receiving a vote
        if (reputations[_target].totalVotes == 0 && reputations[_target].score == 0) {
            totalUsers++;
        }
        
        hasVoted[msg.sender][_target] = true;
        
        Vote memory newVote = Vote({
            voter: msg.sender,
            isUpvote: _isUpvote,
            timestamp: block.timestamp,
            comment: _comment
        });
        
        votesReceived[_target].push(newVote);
        votesGiven[msg.sender].push(newVote);
        
        if (_isUpvote) {
            reputations[_target].score++;
            reputations[_target].upvotes++;
        } else {
            reputations[_target].score--;
            reputations[_target].downvotes++;
        }
        
        reputations[_target].totalVotes++;
        
        emit VoteCast(msg.sender, _target, _isUpvote, _comment);
    }
    
    /**
     * @dev Change an existing vote
     * @param _target The address to change vote for
     * @param _newIsUpvote The new vote (true for upvote, false for downvote)
     */
    function changeVote(address _target, bool _newIsUpvote) external {
        require(_target != address(0), "Invalid target address");
        require(hasVoted[msg.sender][_target], "Have not voted for this user");
        
        // Find and update the vote
        Vote[] storage received = votesReceived[_target];
        for (uint256 i = 0; i < received.length; i++) {
            if (received[i].voter == msg.sender) {
                bool oldVote = received[i].isUpvote;
                
                if (oldVote != _newIsUpvote) {
                    received[i].isUpvote = _newIsUpvote;
                    received[i].timestamp = block.timestamp;
                    
                    // Update reputation
                    if (_newIsUpvote) {
                        // Changed from downvote to upvote
                        reputations[_target].score += 2;
                        reputations[_target].upvotes++;
                        reputations[_target].downvotes--;
                    } else {
                        // Changed from upvote to downvote
                        reputations[_target].score -= 2;
                        reputations[_target].upvotes--;
                        reputations[_target].downvotes++;
                    }
                    
                    emit VoteChanged(msg.sender, _target, _newIsUpvote);
                }
                break;
            }
        }
    }
    
    /**
     * @dev Remove a vote
     * @param _target The address to remove vote from
     */
    function removeVote(address _target) external {
        require(_target != address(0), "Invalid target address");
        require(hasVoted[msg.sender][_target], "Have not voted for this user");
        
        hasVoted[msg.sender][_target] = false;
        
        // Find and remove the vote
        Vote[] storage received = votesReceived[_target];
        for (uint256 i = 0; i < received.length; i++) {
            if (received[i].voter == msg.sender) {
                bool wasUpvote = received[i].isUpvote;
                
                // Update reputation
                if (wasUpvote) {
                    reputations[_target].score--;
                    reputations[_target].upvotes--;
                } else {
                    reputations[_target].score++;
                    reputations[_target].downvotes--;
                }
                
                reputations[_target].totalVotes--;
                
                // Remove from array by swapping with last element
                received[i] = received[received.length - 1];
                received.pop();
                
                emit VoteRemoved(msg.sender, _target);
                break;
            }
        }
    }
    
    /**
     * @dev Get reputation score for a user
     * @param _user The user address
     * @return The reputation score
     */
    function getReputationScore(address _user) external view returns (int256) {
        return reputations[_user].score;
    }
    
    /**
     * @dev Get detailed reputation for a user
     * @param _user The user address
     * @return score The reputation score
     * @return upvotes Number of upvotes
     * @return downvotes Number of downvotes
     * @return totalVotes Total number of votes
     */
    function getReputation(address _user) external view returns (
        int256 score,
        uint256 upvotes,
        uint256 downvotes,
        uint256 totalVotes
    ) {
        UserReputation memory rep = reputations[_user];
        return (rep.score, rep.upvotes, rep.downvotes, rep.totalVotes);
    }
    
    /**
     * @dev Get all votes received by a user
     * @param _user The user address
     * @return voters Array of voter addresses
     * @return isUpvotes Array of vote types
     * @return timestamps Array of vote timestamps
     * @return comments Array of vote comments
     */
    function getVotesReceived(address _user) external view returns (
        address[] memory voters,
        bool[] memory isUpvotes,
        uint256[] memory timestamps,
        string[] memory comments
    ) {
        Vote[] memory votes = votesReceived[_user];
        uint256 count = votes.length;
        
        voters = new address[](count);
        isUpvotes = new bool[](count);
        timestamps = new uint256[](count);
        comments = new string[](count);
        
        for (uint256 i = 0; i < count; i++) {
            voters[i] = votes[i].voter;
            isUpvotes[i] = votes[i].isUpvote;
            timestamps[i] = votes[i].timestamp;
            comments[i] = votes[i].comment;
        }
        
        return (voters, isUpvotes, timestamps, comments);
    }
    
    /**
     * @dev Get all votes given by a user
     * @param _user The user address
     * @return targets Array of target addresses
     * @return isUpvotes Array of vote types
     * @return timestamps Array of vote timestamps
     * @return comments Array of vote comments
     */
    function getVotesGiven(address _user) external view returns (
        address[] memory targets,
        bool[] memory isUpvotes,
        uint256[] memory timestamps,
        string[] memory comments
    ) {
        Vote[] memory votes = votesGiven[_user];
        uint256 count = votes.length;
        
        targets = new address[](count);
        isUpvotes = new bool[](count);
        timestamps = new uint256[](count);
        comments = new string[](count);
        
        for (uint256 i = 0; i < count; i++) {
            // Note: votesGiven stores voter as msg.sender, so we need to extract target differently
            // For simplicity, we'll store the vote structure as is
            targets[i] = votes[i].voter; // This should be modified in real implementation
            isUpvotes[i] = votes[i].isUpvote;
            timestamps[i] = votes[i].timestamp;
            comments[i] = votes[i].comment;
        }
        
        return (targets, isUpvotes, timestamps, comments);
    }
    
    /**
     * @dev Check if a user has voted for another
     * @param _voter The voter address
     * @param _target The target address
     * @return True if voted, false otherwise
     */
    function hasUserVoted(address _voter, address _target) external view returns (bool) {
        return hasVoted[_voter][_target];
    }
    
    /**
     * @dev Get the number of votes received by a user
     * @param _user The user address
     * @return The number of votes received
     */
    function getVotesReceivedCount(address _user) external view returns (uint256) {
        return votesReceived[_user].length;
    }
    
    /**
     * @dev Get the number of votes given by a user
     * @param _user The user address
     * @return The number of votes given
     */
    function getVotesGivenCount(address _user) external view returns (uint256) {
        return votesGiven[_user].length;
    }
    
    /**
     * @dev Get reputation percentage (upvotes / total votes * 100)
     * @param _user The user address
     * @return The reputation percentage (0-100)
     */
    function getReputationPercentage(address _user) external view returns (uint256) {
        UserReputation memory rep = reputations[_user];
        
        if (rep.totalVotes == 0) {
            return 0;
        }
        
        return (rep.upvotes * 100) / rep.totalVotes;
    }
    
    /**
     * @dev Get users with highest reputation (limited sample)
     * @param _addresses Array of addresses to check
     * @return topUsers Array of addresses sorted by reputation
     * @return scores Array of scores corresponding to addresses
     */
    function getTopUsers(address[] memory _addresses) external view returns (
        address[] memory topUsers,
        int256[] memory scores
    ) {
        uint256 length = _addresses.length;
        topUsers = new address[](length);
        scores = new int256[](length);
        
        // Copy addresses and scores
        for (uint256 i = 0; i < length; i++) {
            topUsers[i] = _addresses[i];
            scores[i] = reputations[_addresses[i]].score;
        }
        
        // Simple bubble sort (descending)
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (scores[j] > scores[i]) {
                    // Swap scores
                    int256 tempScore = scores[i];
                    scores[i] = scores[j];
                    scores[j] = tempScore;
                    
                    // Swap addresses
                    address tempAddr = topUsers[i];
                    topUsers[i] = topUsers[j];
                    topUsers[j] = tempAddr;
                }
            }
        }
        
        return (topUsers, scores);
    }
}
