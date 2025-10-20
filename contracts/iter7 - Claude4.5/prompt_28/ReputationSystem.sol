// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ReputationSystem
 * @dev Reputation system where users can upvote or downvote others based on interactions
 */
contract ReputationSystem {
    // Vote type enumeration
    enum VoteType { NONE, UPVOTE, DOWNVOTE }

    // Vote structure
    struct Vote {
        address voter;
        address target;
        VoteType voteType;
        string comment;
        uint256 timestamp;
    }

    // User reputation data
    struct UserReputation {
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
        bool exists;
    }

    // State variables
    address public owner;
    mapping(address => UserReputation) private reputations;
    mapping(address => mapping(address => VoteType)) private userVotes; // voter => target => voteType
    mapping(address => Vote[]) private votesReceived;
    mapping(address => Vote[]) private votesGiven;
    mapping(address => address[]) private votedUsers; // Track who a user has voted for
    
    uint256 public totalVotes;
    address[] private allUsers;
    mapping(address => bool) private isUserRegistered;

    // Events
    event VoteCast(address indexed voter, address indexed target, VoteType voteType, string comment, uint256 timestamp);
    event VoteChanged(address indexed voter, address indexed target, VoteType oldVote, VoteType newVote);
    event VoteRemoved(address indexed voter, address indexed target, VoteType voteType);
    event ReputationUpdated(address indexed user, int256 newScore, uint256 upvotes, uint256 downvotes);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier validAddress(address user) {
        require(user != address(0), "Invalid address");
        _;
    }

    modifier cannotVoteSelf(address target) {
        require(msg.sender != target, "Cannot vote for yourself");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Cast an upvote for a user
     * @param target Address to upvote
     * @param comment Optional comment for the vote
     */
    function upvote(address target, string memory comment) 
        public 
        validAddress(target) 
        cannotVoteSelf(target) 
    {
        _castVote(target, VoteType.UPVOTE, comment);
    }

    /**
     * @dev Cast a downvote for a user
     * @param target Address to downvote
     * @param comment Optional comment for the vote
     */
    function downvote(address target, string memory comment) 
        public 
        validAddress(target) 
        cannotVoteSelf(target) 
    {
        _castVote(target, VoteType.DOWNVOTE, comment);
    }

    /**
     * @dev Remove vote for a user
     * @param target Address to remove vote from
     */
    function removeVote(address target) public validAddress(target) {
        VoteType currentVote = userVotes[msg.sender][target];
        require(currentVote != VoteType.NONE, "No vote to remove");

        _updateReputation(target, currentVote, VoteType.NONE);
        userVotes[msg.sender][target] = VoteType.NONE;

        emit VoteRemoved(msg.sender, target, currentVote);
    }

    /**
     * @dev Internal function to cast a vote
     * @param target Target address
     * @param voteType Type of vote
     * @param comment Comment for the vote
     */
    function _castVote(address target, VoteType voteType, string memory comment) private {
        VoteType currentVote = userVotes[msg.sender][target];

        if (currentVote == voteType) {
            revert("Already voted with this type");
        }

        // Register users if needed
        if (!isUserRegistered[msg.sender]) {
            allUsers.push(msg.sender);
            isUserRegistered[msg.sender] = true;
            reputations[msg.sender].exists = true;
        }
        if (!isUserRegistered[target]) {
            allUsers.push(target);
            isUserRegistered[target] = true;
            reputations[target].exists = true;
        }

        // Create vote record
        Vote memory newVote = Vote({
            voter: msg.sender,
            target: target,
            voteType: voteType,
            comment: comment,
            timestamp: block.timestamp
        });

        votesReceived[target].push(newVote);
        votesGiven[msg.sender].push(newVote);

        if (currentVote == VoteType.NONE) {
            votedUsers[msg.sender].push(target);
            totalVotes++;
        }

        // Update reputation
        _updateReputation(target, currentVote, voteType);
        
        // Update vote mapping
        userVotes[msg.sender][target] = voteType;

        if (currentVote == VoteType.NONE) {
            emit VoteCast(msg.sender, target, voteType, comment, block.timestamp);
        } else {
            emit VoteChanged(msg.sender, target, currentVote, voteType);
        }
    }

    /**
     * @dev Update reputation based on vote change
     * @param target Target user
     * @param oldVote Previous vote type
     * @param newVote New vote type
     */
    function _updateReputation(address target, VoteType oldVote, VoteType newVote) private {
        UserReputation storage rep = reputations[target];

        // Revert old vote effect
        if (oldVote == VoteType.UPVOTE) {
            rep.score -= 1;
            rep.upvotes -= 1;
        } else if (oldVote == VoteType.DOWNVOTE) {
            rep.score += 1;
            rep.downvotes -= 1;
        }

        // Apply new vote effect
        if (newVote == VoteType.UPVOTE) {
            rep.score += 1;
            rep.upvotes += 1;
        } else if (newVote == VoteType.DOWNVOTE) {
            rep.score -= 1;
            rep.downvotes += 1;
        }

        emit ReputationUpdated(target, rep.score, rep.upvotes, rep.downvotes);
    }

    // View Functions

    /**
     * @dev Get reputation score of a user
     * @param user User address
     * @return score Reputation score
     */
    function getReputationScore(address user) public view validAddress(user) returns (int256) {
        return reputations[user].score;
    }

    /**
     * @dev Get full reputation details of a user
     * @param user User address
     * @return score Reputation score
     * @return upvotes Number of upvotes
     * @return downvotes Number of downvotes
     */
    function getReputation(address user) 
        public 
        view 
        validAddress(user) 
        returns (int256 score, uint256 upvotes, uint256 downvotes) 
    {
        UserReputation memory rep = reputations[user];
        return (rep.score, rep.upvotes, rep.downvotes);
    }

    /**
     * @dev Get vote type from voter to target
     * @param voter Voter address
     * @param target Target address
     * @return Vote type
     */
    function getVote(address voter, address target) 
        public 
        view 
        validAddress(voter) 
        validAddress(target) 
        returns (VoteType) 
    {
        return userVotes[voter][target];
    }

    /**
     * @dev Check if a voter has voted for a target
     * @param voter Voter address
     * @param target Target address
     * @return true if voted
     */
    function hasVoted(address voter, address target) public view returns (bool) {
        return userVotes[voter][target] != VoteType.NONE;
    }

    /**
     * @dev Get all votes received by a user
     * @param user User address
     * @return Array of votes
     */
    function getVotesReceived(address user) public view validAddress(user) returns (Vote[] memory) {
        return votesReceived[user];
    }

    /**
     * @dev Get all votes given by a user
     * @param user User address
     * @return Array of votes
     */
    function getVotesGiven(address user) public view validAddress(user) returns (Vote[] memory) {
        return votesGiven[user];
    }

    /**
     * @dev Get number of votes received by a user
     * @param user User address
     * @return Number of votes
     */
    function getVotesReceivedCount(address user) public view validAddress(user) returns (uint256) {
        return votesReceived[user].length;
    }

    /**
     * @dev Get number of votes given by a user
     * @param user User address
     * @return Number of votes
     */
    function getVotesGivenCount(address user) public view validAddress(user) returns (uint256) {
        return votesGiven[user].length;
    }

    /**
     * @dev Get all users a voter has voted for
     * @param voter Voter address
     * @return Array of user addresses
     */
    function getVotedUsers(address voter) public view validAddress(voter) returns (address[] memory) {
        return votedUsers[voter];
    }

    /**
     * @dev Get top N users by reputation score
     * @param n Number of top users to return
     * @return Array of addresses
     * @return Array of scores
     */
    function getTopUsers(uint256 n) public view returns (address[] memory, int256[] memory) {
        uint256 userCount = allUsers.length;
        if (n > userCount) {
            n = userCount;
        }

        address[] memory topAddresses = new address[](n);
        int256[] memory topScores = new int256[](n);

        // Simple selection sort for top N
        for (uint256 i = 0; i < n; i++) {
            int256 maxScore = type(int256).min;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < userCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (topAddresses[k] == allUsers[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && reputations[allUsers[j]].score > maxScore) {
                    maxScore = reputations[allUsers[j]].score;
                    maxIndex = j;
                }
            }

            if (maxScore > type(int256).min) {
                topAddresses[i] = allUsers[maxIndex];
                topScores[i] = maxScore;
            }
        }

        return (topAddresses, topScores);
    }

    /**
     * @dev Get all registered users
     * @return Array of user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return allUsers;
    }

    /**
     * @dev Get total number of registered users
     * @return Number of users
     */
    function getTotalUsers() public view returns (uint256) {
        return allUsers.length;
    }

    /**
     * @dev Get user reputation statistics
     * @param user User address
     * @return score Reputation score
     * @return upvotes Number of upvotes
     * @return downvotes Number of downvotes
     * @return votesReceived Number of votes received
     * @return votesGiven Number of votes given
     */
    function getUserStatistics(address user) 
        public 
        view 
        validAddress(user) 
        returns (
            int256 score,
            uint256 upvotes,
            uint256 downvotes,
            uint256 votesReceivedCount,
            uint256 votesGivenCount
        ) 
    {
        UserReputation memory rep = reputations[user];
        return (
            rep.score,
            rep.upvotes,
            rep.downvotes,
            votesReceived[user].length,
            votesGiven[user].length
        );
    }

    /**
     * @dev Get users with positive reputation
     * @return Array of addresses with positive scores
     */
    function getUsersWithPositiveReputation() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (reputations[allUsers[i]].score > 0) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (reputations[allUsers[i]].score > 0) {
                result[index] = allUsers[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get users with negative reputation
     * @return Array of addresses with negative scores
     */
    function getUsersWithNegativeReputation() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (reputations[allUsers[i]].score < 0) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (reputations[allUsers[i]].score < 0) {
                result[index] = allUsers[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get average reputation score across all users
     * @return Average score (multiplied by 1000 for precision)
     */
    function getAverageReputation() public view returns (int256) {
        if (allUsers.length == 0) {
            return 0;
        }

        int256 totalScore = 0;
        for (uint256 i = 0; i < allUsers.length; i++) {
            totalScore += reputations[allUsers[i]].score;
        }

        return (totalScore * 1000) / int256(allUsers.length);
    }

    /**
     * @dev Check if a user is registered
     * @param user User address
     * @return Registration status
     */
    function isRegistered(address user) public view returns (bool) {
        return isUserRegistered[user];
    }
}
