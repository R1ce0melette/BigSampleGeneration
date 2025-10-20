// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    struct UserReputation {
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
        bool exists;
    }
    
    struct Vote {
        address voter;
        address recipient;
        bool isUpvote;
        uint256 timestamp;
        string comment;
    }
    
    mapping(address => UserReputation) public userReputations;
    mapping(address => mapping(address => bool)) public hasVoted;
    mapping(address => Vote[]) public votesReceived;
    mapping(address => Vote[]) public votesGiven;
    
    uint256 public totalVotes;
    
    event VoteCast(address indexed voter, address indexed recipient, bool isUpvote, uint256 timestamp);
    event VoteChanged(address indexed voter, address indexed recipient, bool newVote);
    event VoteRemoved(address indexed voter, address indexed recipient);
    
    function upvote(address _recipient, string memory _comment) external {
        require(_recipient != address(0), "Invalid recipient address");
        require(_recipient != msg.sender, "Cannot vote for yourself");
        require(!hasVoted[msg.sender][_recipient], "Already voted for this user");
        
        if (!userReputations[_recipient].exists) {
            userReputations[_recipient].exists = true;
        }
        
        hasVoted[msg.sender][_recipient] = true;
        userReputations[_recipient].score++;
        userReputations[_recipient].upvotes++;
        
        Vote memory newVote = Vote({
            voter: msg.sender,
            recipient: _recipient,
            isUpvote: true,
            timestamp: block.timestamp,
            comment: _comment
        });
        
        votesReceived[_recipient].push(newVote);
        votesGiven[msg.sender].push(newVote);
        totalVotes++;
        
        emit VoteCast(msg.sender, _recipient, true, block.timestamp);
    }
    
    function downvote(address _recipient, string memory _comment) external {
        require(_recipient != address(0), "Invalid recipient address");
        require(_recipient != msg.sender, "Cannot vote for yourself");
        require(!hasVoted[msg.sender][_recipient], "Already voted for this user");
        
        if (!userReputations[_recipient].exists) {
            userReputations[_recipient].exists = true;
        }
        
        hasVoted[msg.sender][_recipient] = true;
        userReputations[_recipient].score--;
        userReputations[_recipient].downvotes++;
        
        Vote memory newVote = Vote({
            voter: msg.sender,
            recipient: _recipient,
            isUpvote: false,
            timestamp: block.timestamp,
            comment: _comment
        });
        
        votesReceived[_recipient].push(newVote);
        votesGiven[msg.sender].push(newVote);
        totalVotes++;
        
        emit VoteCast(msg.sender, _recipient, false, block.timestamp);
    }
    
    function changeVote(address _recipient, bool _newVote, string memory _comment) external {
        require(_recipient != address(0), "Invalid recipient address");
        require(_recipient != msg.sender, "Cannot vote for yourself");
        require(hasVoted[msg.sender][_recipient], "Haven't voted for this user yet");
        
        // Find and update the previous vote
        bool previousVote = false;
        Vote[] storage receivedVotes = votesReceived[_recipient];
        
        for (uint256 i = 0; i < receivedVotes.length; i++) {
            if (receivedVotes[i].voter == msg.sender) {
                previousVote = receivedVotes[i].isUpvote;
                receivedVotes[i].isUpvote = _newVote;
                receivedVotes[i].timestamp = block.timestamp;
                receivedVotes[i].comment = _comment;
                break;
            }
        }
        
        // Update votes given
        Vote[] storage givenVotes = votesGiven[msg.sender];
        for (uint256 i = 0; i < givenVotes.length; i++) {
            if (givenVotes[i].recipient == _recipient) {
                givenVotes[i].isUpvote = _newVote;
                givenVotes[i].timestamp = block.timestamp;
                givenVotes[i].comment = _comment;
                break;
            }
        }
        
        // Update reputation
        if (previousVote && !_newVote) {
            // Changed from upvote to downvote
            userReputations[_recipient].score -= 2;
            userReputations[_recipient].upvotes--;
            userReputations[_recipient].downvotes++;
        } else if (!previousVote && _newVote) {
            // Changed from downvote to upvote
            userReputations[_recipient].score += 2;
            userReputations[_recipient].downvotes--;
            userReputations[_recipient].upvotes++;
        }
        
        emit VoteChanged(msg.sender, _recipient, _newVote);
    }
    
    function removeVote(address _recipient) external {
        require(_recipient != address(0), "Invalid recipient address");
        require(hasVoted[msg.sender][_recipient], "Haven't voted for this user");
        
        // Find and determine the vote type
        bool wasUpvote = false;
        Vote[] storage receivedVotes = votesReceived[_recipient];
        
        for (uint256 i = 0; i < receivedVotes.length; i++) {
            if (receivedVotes[i].voter == msg.sender) {
                wasUpvote = receivedVotes[i].isUpvote;
                // Remove vote by replacing with last element and popping
                receivedVotes[i] = receivedVotes[receivedVotes.length - 1];
                receivedVotes.pop();
                break;
            }
        }
        
        // Remove from votes given
        Vote[] storage givenVotes = votesGiven[msg.sender];
        for (uint256 i = 0; i < givenVotes.length; i++) {
            if (givenVotes[i].recipient == _recipient) {
                givenVotes[i] = givenVotes[givenVotes.length - 1];
                givenVotes.pop();
                break;
            }
        }
        
        // Update reputation
        if (wasUpvote) {
            userReputations[_recipient].score--;
            userReputations[_recipient].upvotes--;
        } else {
            userReputations[_recipient].score++;
            userReputations[_recipient].downvotes--;
        }
        
        hasVoted[msg.sender][_recipient] = false;
        totalVotes--;
        
        emit VoteRemoved(msg.sender, _recipient);
    }
    
    function getReputation(address _user) external view returns (
        int256 score,
        uint256 upvotes,
        uint256 downvotes
    ) {
        UserReputation memory rep = userReputations[_user];
        return (rep.score, rep.upvotes, rep.downvotes);
    }
    
    function getReputationScore(address _user) external view returns (int256) {
        return userReputations[_user].score;
    }
    
    function hasUserVoted(address _voter, address _recipient) external view returns (bool) {
        return hasVoted[_voter][_recipient];
    }
    
    function getVotesReceived(address _user) external view returns (Vote[] memory) {
        return votesReceived[_user];
    }
    
    function getVotesGiven(address _user) external view returns (Vote[] memory) {
        return votesGiven[_user];
    }
    
    function getVoteCount(address _user) external view returns (uint256 received, uint256 given) {
        return (votesReceived[_user].length, votesGiven[_user].length);
    }
    
    function getMyReputation() external view returns (
        int256 score,
        uint256 upvotes,
        uint256 downvotes
    ) {
        UserReputation memory rep = userReputations[msg.sender];
        return (rep.score, rep.upvotes, rep.downvotes);
    }
}
