// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct UserReputation {
        int256 reputationScore;
        uint256 upvotes;
        uint256 downvotes;
        uint256 totalInteractions;
    }
    
    struct Vote {
        address voter;
        address target;
        bool isUpvote;
        uint256 timestamp;
        string reason;
    }
    
    mapping(address => UserReputation) public userReputations;
    mapping(address => mapping(address => bool)) public hasVoted;
    mapping(address => mapping(address => bool)) public voteType; // true = upvote, false = downvote
    
    Vote[] public voteHistory;
    mapping(address => uint256[]) public userReceivedVotes;
    mapping(address => uint256[]) public userGivenVotes;
    
    event Upvoted(address indexed voter, address indexed target, uint256 timestamp);
    event Downvoted(address indexed voter, address indexed target, uint256 timestamp);
    event VoteChanged(address indexed voter, address indexed target, bool isUpvote, uint256 timestamp);
    event VoteRemoved(address indexed voter, address indexed target, uint256 timestamp);
    
    function upvote(address _target, string memory _reason) external {
        require(_target != address(0), "Target cannot be zero address");
        require(_target != msg.sender, "Cannot vote for yourself");
        
        if (hasVoted[msg.sender][_target]) {
            // If already voted, change the vote
            if (!voteType[msg.sender][_target]) {
                // Was downvote, change to upvote
                userReputations[_target].downvotes--;
                userReputations[_target].upvotes++;
                userReputations[_target].reputationScore += 2; // +1 to remove downvote, +1 for upvote
                
                voteType[msg.sender][_target] = true;
                
                emit VoteChanged(msg.sender, _target, true, block.timestamp);
            }
            // If already upvoted, do nothing
            return;
        }
        
        hasVoted[msg.sender][_target] = true;
        voteType[msg.sender][_target] = true;
        
        userReputations[_target].upvotes++;
        userReputations[_target].reputationScore++;
        userReputations[_target].totalInteractions++;
        
        uint256 voteIndex = voteHistory.length;
        voteHistory.push(Vote({
            voter: msg.sender,
            target: _target,
            isUpvote: true,
            timestamp: block.timestamp,
            reason: _reason
        }));
        
        userReceivedVotes[_target].push(voteIndex);
        userGivenVotes[msg.sender].push(voteIndex);
        
        emit Upvoted(msg.sender, _target, block.timestamp);
    }
    
    function downvote(address _target, string memory _reason) external {
        require(_target != address(0), "Target cannot be zero address");
        require(_target != msg.sender, "Cannot vote for yourself");
        
        if (hasVoted[msg.sender][_target]) {
            // If already voted, change the vote
            if (voteType[msg.sender][_target]) {
                // Was upvote, change to downvote
                userReputations[_target].upvotes--;
                userReputations[_target].downvotes++;
                userReputations[_target].reputationScore -= 2; // -1 to remove upvote, -1 for downvote
                
                voteType[msg.sender][_target] = false;
                
                emit VoteChanged(msg.sender, _target, false, block.timestamp);
            }
            // If already downvoted, do nothing
            return;
        }
        
        hasVoted[msg.sender][_target] = true;
        voteType[msg.sender][_target] = false;
        
        userReputations[_target].downvotes++;
        userReputations[_target].reputationScore--;
        userReputations[_target].totalInteractions++;
        
        uint256 voteIndex = voteHistory.length;
        voteHistory.push(Vote({
            voter: msg.sender,
            target: _target,
            isUpvote: false,
            timestamp: block.timestamp,
            reason: _reason
        }));
        
        userReceivedVotes[_target].push(voteIndex);
        userGivenVotes[msg.sender].push(voteIndex);
        
        emit Downvoted(msg.sender, _target, block.timestamp);
    }
    
    function removeVote(address _target) external {
        require(hasVoted[msg.sender][_target], "You have not voted for this address");
        
        if (voteType[msg.sender][_target]) {
            // Was upvote
            userReputations[_target].upvotes--;
            userReputations[_target].reputationScore--;
        } else {
            // Was downvote
            userReputations[_target].downvotes--;
            userReputations[_target].reputationScore++;
        }
        
        userReputations[_target].totalInteractions--;
        
        hasVoted[msg.sender][_target] = false;
        delete voteType[msg.sender][_target];
        
        emit VoteRemoved(msg.sender, _target, block.timestamp);
    }
    
    function getReputation(address _user) external view returns (
        int256 reputationScore,
        uint256 upvotes,
        uint256 downvotes,
        uint256 totalInteractions
    ) {
        UserReputation memory rep = userReputations[_user];
        return (
            rep.reputationScore,
            rep.upvotes,
            rep.downvotes,
            rep.totalInteractions
        );
    }
    
    function getReputationScore(address _user) external view returns (int256) {
        return userReputations[_user].reputationScore;
    }
    
    function hasUserVoted(address _voter, address _target) external view returns (bool) {
        return hasVoted[_voter][_target];
    }
    
    function getUserVoteType(address _voter, address _target) external view returns (bool) {
        require(hasVoted[_voter][_target], "User has not voted for this address");
        return voteType[_voter][_target];
    }
    
    function getVote(uint256 _voteIndex) external view returns (
        address voter,
        address target,
        bool isUpvote,
        uint256 timestamp,
        string memory reason
    ) {
        require(_voteIndex < voteHistory.length, "Invalid vote index");
        Vote memory vote = voteHistory[_voteIndex];
        
        return (
            vote.voter,
            vote.target,
            vote.isUpvote,
            vote.timestamp,
            vote.reason
        );
    }
    
    function getUserReceivedVotes(address _user) external view returns (uint256[] memory) {
        return userReceivedVotes[_user];
    }
    
    function getUserGivenVotes(address _user) external view returns (uint256[] memory) {
        return userGivenVotes[_user];
    }
    
    function getTotalVotes() external view returns (uint256) {
        return voteHistory.length;
    }
    
    function getReputationPercentage(address _user) external view returns (uint256) {
        UserReputation memory rep = userReputations[_user];
        
        if (rep.totalInteractions == 0) {
            return 50; // Neutral 50% if no interactions
        }
        
        return (rep.upvotes * 100) / rep.totalInteractions;
    }
    
    function compareReputation(address _user1, address _user2) external view returns (int256) {
        int256 score1 = userReputations[_user1].reputationScore;
        int256 score2 = userReputations[_user2].reputationScore;
        
        return score1 - score2; // Positive if user1 has higher reputation
    }
    
    function getTopUsers(uint256 _count) external view returns (address[] memory, int256[] memory) {
        // This is a simplified implementation
        // For production, consider using off-chain indexing for efficiency
        require(_count > 0, "Count must be greater than 0");
        
        address[] memory topUsers = new address[](_count);
        int256[] memory topScores = new int256[](_count);
        
        return (topUsers, topScores);
    }
}
