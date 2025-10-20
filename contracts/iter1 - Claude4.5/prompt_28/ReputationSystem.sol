// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ReputationSystem
 * @dev A reputation system where users can upvote or downvote others based on interactions
 */
contract ReputationSystem {
    struct UserReputation {
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
        uint256 totalInteractions;
        bool registered;
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
    mapping(address => mapping(address => Vote)) public votes;
    mapping(address => Vote[]) private votesReceived;
    mapping(address => Vote[]) private votesGiven;
    
    address[] private registeredUsers;
    uint256 private voteCounter;
    
    address public owner;
    int256 public constant UPVOTE_VALUE = 1;
    int256 public constant DOWNVOTE_VALUE = -1;
    
    event UserRegistered(address indexed user);
    event VoteCast(
        address indexed voter,
        address indexed target,
        bool isUpvote,
        int256 newScore,
        uint256 timestamp
    );
    event VoteChanged(
        address indexed voter,
        address indexed target,
        bool newIsUpvote,
        int256 newScore
    );
    event VoteRemoved(
        address indexed voter,
        address indexed target,
        int256 newScore
    );
    
    modifier onlyRegistered() {
        require(userReputations[msg.sender].registered, "User not registered");
        _;
    }
    
    modifier targetRegistered(address target) {
        require(userReputations[target].registered, "Target user not registered");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a user in the reputation system
     */
    function registerUser() external {
        require(!userReputations[msg.sender].registered, "User already registered");
        
        userReputations[msg.sender] = UserReputation({
            score: 0,
            upvotes: 0,
            downvotes: 0,
            totalInteractions: 0,
            registered: true
        });
        
        registeredUsers.push(msg.sender);
        
        emit UserRegistered(msg.sender);
    }
    
    /**
     * @dev Cast an upvote for another user
     * @param target The address to upvote
     * @param reason Optional reason for the vote
     */
    function upvote(address target, string memory reason) 
        external 
        onlyRegistered 
        targetRegistered(target) 
    {
        require(target != msg.sender, "Cannot vote for yourself");
        require(!hasVoted[msg.sender][target], "Already voted for this user");
        
        _castVote(target, true, reason);
    }
    
    /**
     * @dev Cast a downvote for another user
     * @param target The address to downvote
     * @param reason Optional reason for the vote
     */
    function downvote(address target, string memory reason) 
        external 
        onlyRegistered 
        targetRegistered(target) 
    {
        require(target != msg.sender, "Cannot vote for yourself");
        require(!hasVoted[msg.sender][target], "Already voted for this user");
        
        _castVote(target, false, reason);
    }
    
    /**
     * @dev Change an existing vote
     * @param target The address whose vote to change
     * @param newIsUpvote Whether the new vote is an upvote
     * @param newReason Optional new reason for the vote
     */
    function changeVote(address target, bool newIsUpvote, string memory newReason) 
        external 
        onlyRegistered 
        targetRegistered(target) 
    {
        require(hasVoted[msg.sender][target], "No existing vote to change");
        
        Vote storage existingVote = votes[msg.sender][target];
        require(existingVote.isUpvote != newIsUpvote, "Vote is already set to this value");
        
        UserReputation storage targetRep = userReputations[target];
        
        // Reverse the old vote
        if (existingVote.isUpvote) {
            targetRep.score -= UPVOTE_VALUE;
            targetRep.upvotes--;
        } else {
            targetRep.score -= DOWNVOTE_VALUE;
            targetRep.downvotes--;
        }
        
        // Apply the new vote
        if (newIsUpvote) {
            targetRep.score += UPVOTE_VALUE;
            targetRep.upvotes++;
        } else {
            targetRep.score += DOWNVOTE_VALUE;
            targetRep.downvotes++;
        }
        
        // Update vote record
        existingVote.isUpvote = newIsUpvote;
        existingVote.timestamp = block.timestamp;
        existingVote.reason = newReason;
        
        emit VoteChanged(msg.sender, target, newIsUpvote, targetRep.score);
    }
    
    /**
     * @dev Remove a vote
     * @param target The address whose vote to remove
     */
    function removeVote(address target) 
        external 
        onlyRegistered 
        targetRegistered(target) 
    {
        require(hasVoted[msg.sender][target], "No vote to remove");
        
        Vote storage existingVote = votes[msg.sender][target];
        UserReputation storage targetRep = userReputations[target];
        
        // Reverse the vote
        if (existingVote.isUpvote) {
            targetRep.score -= UPVOTE_VALUE;
            targetRep.upvotes--;
        } else {
            targetRep.score -= DOWNVOTE_VALUE;
            targetRep.downvotes--;
        }
        
        targetRep.totalInteractions--;
        hasVoted[msg.sender][target] = false;
        
        // Remove from votesReceived array
        Vote[] storage receivedVotes = votesReceived[target];
        for (uint256 i = 0; i < receivedVotes.length; i++) {
            if (receivedVotes[i].voter == msg.sender) {
                receivedVotes[i] = receivedVotes[receivedVotes.length - 1];
                receivedVotes.pop();
                break;
            }
        }
        
        // Remove from votesGiven array
        Vote[] storage givenVotes = votesGiven[msg.sender];
        for (uint256 i = 0; i < givenVotes.length; i++) {
            if (givenVotes[i].target == target) {
                givenVotes[i] = givenVotes[givenVotes.length - 1];
                givenVotes.pop();
                break;
            }
        }
        
        delete votes[msg.sender][target];
        
        emit VoteRemoved(msg.sender, target, targetRep.score);
    }
    
    /**
     * @dev Get reputation details for a user
     * @param user The user's address
     * @return score Current reputation score
     * @return upvotes Number of upvotes
     * @return downvotes Number of downvotes
     * @return totalInteractions Total interactions
     * @return registered Whether user is registered
     */
    function getReputation(address user) external view returns (
        int256 score,
        uint256 upvotes,
        uint256 downvotes,
        uint256 totalInteractions,
        bool registered
    ) {
        UserReputation memory rep = userReputations[user];
        return (
            rep.score,
            rep.upvotes,
            rep.downvotes,
            rep.totalInteractions,
            rep.registered
        );
    }
    
    /**
     * @dev Get the vote one user cast for another
     * @param voter The voter's address
     * @param target The target's address
     * @return isUpvote Whether it's an upvote
     * @return timestamp When the vote was cast
     * @return reason The reason for the vote
     * @return exists Whether the vote exists
     */
    function getVote(address voter, address target) external view returns (
        bool isUpvote,
        uint256 timestamp,
        string memory reason,
        bool exists
    ) {
        if (!hasVoted[voter][target]) {
            return (false, 0, "", false);
        }
        
        Vote memory vote = votes[voter][target];
        return (vote.isUpvote, vote.timestamp, vote.reason, true);
    }
    
    /**
     * @dev Get all votes received by a user
     * @param user The user's address
     * @return Array of votes
     */
    function getVotesReceived(address user) external view returns (Vote[] memory) {
        return votesReceived[user];
    }
    
    /**
     * @dev Get all votes given by a user
     * @param user The user's address
     * @return Array of votes
     */
    function getVotesGiven(address user) external view returns (Vote[] memory) {
        return votesGiven[user];
    }
    
    /**
     * @dev Get reputation score for a user
     * @param user The user's address
     * @return The reputation score
     */
    function getReputationScore(address user) external view returns (int256) {
        return userReputations[user].score;
    }
    
    /**
     * @dev Check if a user has voted for another user
     * @param voter The voter's address
     * @param target The target's address
     * @return Whether the vote exists
     */
    function hasUserVoted(address voter, address target) external view returns (bool) {
        return hasVoted[voter][target];
    }
    
    /**
     * @dev Get all registered users
     * @return Array of registered user addresses
     */
    function getRegisteredUsers() external view returns (address[] memory) {
        return registeredUsers;
    }
    
    /**
     * @dev Get users sorted by reputation score (top N)
     * @param count Number of top users to return
     * @return Array of user addresses sorted by score
     */
    function getTopUsers(uint256 count) external view returns (address[] memory) {
        uint256 totalUsers = registeredUsers.length;
        uint256 resultCount = count > totalUsers ? totalUsers : count;
        
        if (resultCount == 0) {
            return new address[](0);
        }
        
        // Create a copy of registered users for sorting
        address[] memory sortedUsers = new address[](totalUsers);
        for (uint256 i = 0; i < totalUsers; i++) {
            sortedUsers[i] = registeredUsers[i];
        }
        
        // Simple bubble sort (descending by score)
        for (uint256 i = 0; i < totalUsers; i++) {
            for (uint256 j = i + 1; j < totalUsers; j++) {
                if (userReputations[sortedUsers[i]].score < userReputations[sortedUsers[j]].score) {
                    address temp = sortedUsers[i];
                    sortedUsers[i] = sortedUsers[j];
                    sortedUsers[j] = temp;
                }
            }
        }
        
        // Return top N
        address[] memory result = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = sortedUsers[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get users with negative reputation
     * @return Array of user addresses with negative scores
     */
    function getUsersWithNegativeReputation() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count users with negative reputation
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            if (userReputations[registeredUsers[i]].score < 0) {
                count++;
            }
        }
        
        // Create array and populate
        address[] memory result = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            if (userReputations[registeredUsers[i]].score < 0) {
                result[index] = registeredUsers[i];
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Get the total number of registered users
     * @return The count of registered users
     */
    function getTotalRegisteredUsers() external view returns (uint256) {
        return registeredUsers.length;
    }
    
    /**
     * @dev Check if a user is registered
     * @param user The user's address
     * @return Whether the user is registered
     */
    function isUserRegistered(address user) external view returns (bool) {
        return userReputations[user].registered;
    }
    
    /**
     * @dev Get upvote percentage for a user
     * @param user The user's address
     * @return Percentage of upvotes (0-100)
     */
    function getUpvotePercentage(address user) external view returns (uint256) {
        UserReputation memory rep = userReputations[user];
        
        if (rep.totalInteractions == 0) {
            return 0;
        }
        
        return (rep.upvotes * 100) / rep.totalInteractions;
    }
    
    /**
     * @dev Internal function to cast a vote
     * @param target The target user
     * @param isUpvote Whether it's an upvote
     * @param reason The reason for the vote
     */
    function _castVote(address target, bool isUpvote, string memory reason) private {
        UserReputation storage targetRep = userReputations[target];
        
        if (isUpvote) {
            targetRep.score += UPVOTE_VALUE;
            targetRep.upvotes++;
        } else {
            targetRep.score += DOWNVOTE_VALUE;
            targetRep.downvotes++;
        }
        
        targetRep.totalInteractions++;
        hasVoted[msg.sender][target] = true;
        
        Vote memory newVote = Vote({
            voter: msg.sender,
            target: target,
            isUpvote: isUpvote,
            timestamp: block.timestamp,
            reason: reason
        });
        
        votes[msg.sender][target] = newVote;
        votesReceived[target].push(newVote);
        votesGiven[msg.sender].push(newVote);
        
        voteCounter++;
        
        emit VoteCast(msg.sender, target, isUpvote, targetRep.score, block.timestamp);
    }
}
