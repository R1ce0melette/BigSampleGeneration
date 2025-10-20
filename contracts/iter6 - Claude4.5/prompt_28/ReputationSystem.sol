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
        bool exists;
    }
    
    struct Vote {
        address voter;
        address target;
        bool isUpvote;
        string comment;
        uint256 timestamp;
    }
    
    address public owner;
    
    mapping(address => UserReputation) public reputations;
    mapping(address => mapping(address => bool)) public hasVoted;
    mapping(address => mapping(address => bool)) public lastVoteWasUpvote;
    mapping(address => Vote[]) public votesReceived;
    mapping(address => Vote[]) public votesGiven;
    
    Vote[] public allVotes;
    address[] public users;
    mapping(address => bool) private isRegisteredUser;
    
    // Events
    event Upvoted(address indexed voter, address indexed target, string comment, uint256 timestamp);
    event Downvoted(address indexed voter, address indexed target, string comment, uint256 timestamp);
    event VoteChanged(address indexed voter, address indexed target, bool isUpvote, uint256 timestamp);
    event VoteRemoved(address indexed voter, address indexed target, uint256 timestamp);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier validAddress(address user) {
        require(user != address(0), "Invalid address");
        _;
    }
    
    modifier cannotVoteSelf(address target) {
        require(msg.sender != target, "Cannot vote for yourself");
        _;
    }
    
    /**
     * @dev Register a user (creates reputation profile)
     */
    function registerUser() external {
        if (!reputations[msg.sender].exists) {
            reputations[msg.sender] = UserReputation({
                score: 0,
                upvotes: 0,
                downvotes: 0,
                exists: true
            });
            
            if (!isRegisteredUser[msg.sender]) {
                users.push(msg.sender);
                isRegisteredUser[msg.sender] = true;
            }
        }
    }
    
    /**
     * @dev Upvote a user
     * @param target The address to upvote
     * @param comment Optional comment for the vote
     */
    function upvote(address target, string memory comment) external validAddress(target) cannotVoteSelf(target) {
        // Ensure target has a reputation profile
        if (!reputations[target].exists) {
            reputations[target] = UserReputation({
                score: 0,
                upvotes: 0,
                downvotes: 0,
                exists: true
            });
            
            if (!isRegisteredUser[target]) {
                users.push(target);
                isRegisteredUser[target] = true;
            }
        }
        
        // Ensure voter has a reputation profile
        if (!reputations[msg.sender].exists) {
            reputations[msg.sender] = UserReputation({
                score: 0,
                upvotes: 0,
                downvotes: 0,
                exists: true
            });
            
            if (!isRegisteredUser[msg.sender]) {
                users.push(msg.sender);
                isRegisteredUser[msg.sender] = true;
            }
        }
        
        if (hasVoted[msg.sender][target]) {
            // If already voted, check if changing vote
            if (!lastVoteWasUpvote[msg.sender][target]) {
                // Changing from downvote to upvote
                reputations[target].downvotes--;
                reputations[target].upvotes++;
                reputations[target].score += 2; // Remove -1 and add +1
                lastVoteWasUpvote[msg.sender][target] = true;
                
                emit VoteChanged(msg.sender, target, true, block.timestamp);
            }
            // If already upvoted, do nothing (or could revert)
        } else {
            // New vote
            reputations[target].upvotes++;
            reputations[target].score++;
            hasVoted[msg.sender][target] = true;
            lastVoteWasUpvote[msg.sender][target] = true;
            
            emit Upvoted(msg.sender, target, comment, block.timestamp);
        }
        
        // Record vote
        Vote memory newVote = Vote({
            voter: msg.sender,
            target: target,
            isUpvote: true,
            comment: comment,
            timestamp: block.timestamp
        });
        
        votesReceived[target].push(newVote);
        votesGiven[msg.sender].push(newVote);
        allVotes.push(newVote);
    }
    
    /**
     * @dev Downvote a user
     * @param target The address to downvote
     * @param comment Optional comment for the vote
     */
    function downvote(address target, string memory comment) external validAddress(target) cannotVoteSelf(target) {
        // Ensure target has a reputation profile
        if (!reputations[target].exists) {
            reputations[target] = UserReputation({
                score: 0,
                upvotes: 0,
                downvotes: 0,
                exists: true
            });
            
            if (!isRegisteredUser[target]) {
                users.push(target);
                isRegisteredUser[target] = true;
            }
        }
        
        // Ensure voter has a reputation profile
        if (!reputations[msg.sender].exists) {
            reputations[msg.sender] = UserReputation({
                score: 0,
                upvotes: 0,
                downvotes: 0,
                exists: true
            });
            
            if (!isRegisteredUser[msg.sender]) {
                users.push(msg.sender);
                isRegisteredUser[msg.sender] = true;
            }
        }
        
        if (hasVoted[msg.sender][target]) {
            // If already voted, check if changing vote
            if (lastVoteWasUpvote[msg.sender][target]) {
                // Changing from upvote to downvote
                reputations[target].upvotes--;
                reputations[target].downvotes++;
                reputations[target].score -= 2; // Remove +1 and add -1
                lastVoteWasUpvote[msg.sender][target] = false;
                
                emit VoteChanged(msg.sender, target, false, block.timestamp);
            }
            // If already downvoted, do nothing (or could revert)
        } else {
            // New vote
            reputations[target].downvotes++;
            reputations[target].score--;
            hasVoted[msg.sender][target] = true;
            lastVoteWasUpvote[msg.sender][target] = false;
            
            emit Downvoted(msg.sender, target, comment, block.timestamp);
        }
        
        // Record vote
        Vote memory newVote = Vote({
            voter: msg.sender,
            target: target,
            isUpvote: false,
            comment: comment,
            timestamp: block.timestamp
        });
        
        votesReceived[target].push(newVote);
        votesGiven[msg.sender].push(newVote);
        allVotes.push(newVote);
    }
    
    /**
     * @dev Remove a vote
     * @param target The address to remove vote from
     */
    function removeVote(address target) external validAddress(target) {
        require(hasVoted[msg.sender][target], "You have not voted for this user");
        
        if (lastVoteWasUpvote[msg.sender][target]) {
            reputations[target].upvotes--;
            reputations[target].score--;
        } else {
            reputations[target].downvotes--;
            reputations[target].score++;
        }
        
        hasVoted[msg.sender][target] = false;
        delete lastVoteWasUpvote[msg.sender][target];
        
        emit VoteRemoved(msg.sender, target, block.timestamp);
    }
    
    /**
     * @dev Get reputation of a user
     * @param user The address to query
     * @return score The reputation score
     * @return upvotes Total upvotes
     * @return downvotes Total downvotes
     */
    function getReputation(address user) external view returns (int256 score, uint256 upvotes, uint256 downvotes) {
        require(reputations[user].exists, "User has no reputation profile");
        UserReputation memory rep = reputations[user];
        return (rep.score, rep.upvotes, rep.downvotes);
    }
    
    /**
     * @dev Get reputation score only
     * @param user The address to query
     * @return The reputation score
     */
    function getScore(address user) external view returns (int256) {
        if (!reputations[user].exists) {
            return 0;
        }
        return reputations[user].score;
    }
    
    /**
     * @dev Check if voter has voted for target
     * @param voter The voter address
     * @param target The target address
     * @return hasVotedResult True if voted
     * @return wasUpvote True if last vote was upvote (only valid if hasVotedResult is true)
     */
    function checkVoteStatus(address voter, address target) external view returns (bool hasVotedResult, bool wasUpvote) {
        return (hasVoted[voter][target], lastVoteWasUpvote[voter][target]);
    }
    
    /**
     * @dev Get all votes received by a user
     * @param user The address to query
     * @return Array of votes
     */
    function getVotesReceived(address user) external view returns (Vote[] memory) {
        return votesReceived[user];
    }
    
    /**
     * @dev Get all votes given by a user
     * @param user The address to query
     * @return Array of votes
     */
    function getVotesGiven(address user) external view returns (Vote[] memory) {
        return votesGiven[user];
    }
    
    /**
     * @dev Get total number of votes in the system
     * @return Total votes count
     */
    function getTotalVotes() external view returns (uint256) {
        return allVotes.length;
    }
    
    /**
     * @dev Get all registered users
     * @return Array of user addresses
     */
    function getAllUsers() external view returns (address[] memory) {
        return users;
    }
    
    /**
     * @dev Get top users by reputation score
     * @param count Number of top users to return
     * @return Array of user addresses sorted by score
     */
    function getTopUsers(uint256 count) external view returns (address[] memory) {
        uint256 userCount = users.length;
        if (count > userCount) {
            count = userCount;
        }
        
        address[] memory topUsers = new address[](count);
        int256[] memory topScores = new int256[](count);
        
        // Initialize with lowest possible scores
        for (uint256 i = 0; i < count; i++) {
            topScores[i] = type(int256).min;
        }
        
        // Find top users
        for (uint256 i = 0; i < userCount; i++) {
            address user = users[i];
            int256 score = reputations[user].score;
            
            // Check if this score belongs in top
            for (uint256 j = 0; j < count; j++) {
                if (score > topScores[j]) {
                    // Shift down lower scores
                    for (uint256 k = count - 1; k > j; k--) {
                        topScores[k] = topScores[k - 1];
                        topUsers[k] = topUsers[k - 1];
                    }
                    // Insert new top user
                    topScores[j] = score;
                    topUsers[j] = user;
                    break;
                }
            }
        }
        
        return topUsers;
    }
    
    /**
     * @dev Get users with lowest reputation
     * @param count Number of users to return
     * @return Array of user addresses sorted by score (lowest first)
     */
    function getLowestUsers(uint256 count) external view returns (address[] memory) {
        uint256 userCount = users.length;
        if (count > userCount) {
            count = userCount;
        }
        
        address[] memory lowestUsers = new address[](count);
        int256[] memory lowestScores = new int256[](count);
        
        // Initialize with highest possible scores
        for (uint256 i = 0; i < count; i++) {
            lowestScores[i] = type(int256).max;
        }
        
        // Find lowest users
        for (uint256 i = 0; i < userCount; i++) {
            address user = users[i];
            int256 score = reputations[user].score;
            
            // Check if this score belongs in lowest
            for (uint256 j = 0; j < count; j++) {
                if (score < lowestScores[j]) {
                    // Shift up higher scores
                    for (uint256 k = count - 1; k > j; k--) {
                        lowestScores[k] = lowestScores[k - 1];
                        lowestUsers[k] = lowestUsers[k - 1];
                    }
                    // Insert new lowest user
                    lowestScores[j] = score;
                    lowestUsers[j] = user;
                    break;
                }
            }
        }
        
        return lowestUsers;
    }
    
    /**
     * @dev Get total number of registered users
     * @return Total user count
     */
    function getTotalUsers() external view returns (uint256) {
        return users.length;
    }
    
    /**
     * @dev Check if a user is registered
     * @param user The address to check
     * @return True if registered
     */
    function isUserRegistered(address user) external view returns (bool) {
        return reputations[user].exists;
    }
}
