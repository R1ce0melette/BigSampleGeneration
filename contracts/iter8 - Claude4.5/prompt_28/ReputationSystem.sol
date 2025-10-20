// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ReputationSystem
 * @dev Contract for a reputation system where users can upvote or downvote others based on interactions
 */
contract ReputationSystem {
    // Vote type enum
    enum VoteType {
        Upvote,
        Downvote
    }

    // Vote structure
    struct Vote {
        uint256 id;
        address voter;
        address recipient;
        VoteType voteType;
        string comment;
        uint256 timestamp;
    }

    // User reputation structure
    struct UserReputation {
        address user;
        int256 score;
        uint256 upvotes;
        uint256 downvotes;
        uint256 totalVotesReceived;
        uint256 totalVotesGiven;
        uint256 registeredAt;
    }

    // Interaction structure
    struct Interaction {
        uint256 id;
        address user1;
        address user2;
        bool hasVoted;
        VoteType voteType;
        uint256 timestamp;
    }

    // State variables
    address public owner;
    uint256 private voteCounter;
    uint256 private interactionCounter;
    
    int256 public constant UPVOTE_POINTS = 1;
    int256 public constant DOWNVOTE_POINTS = -1;
    uint256 public constant COOLDOWN_PERIOD = 1 days;

    mapping(address => UserReputation) private userReputations;
    mapping(address => bool) public isRegistered;
    mapping(uint256 => Vote) private votes;
    mapping(address => uint256[]) private votesReceived;
    mapping(address => uint256[]) private votesGiven;
    mapping(bytes32 => bool) private hasVoted; // hash(voter, recipient) => hasVoted in cooldown
    mapping(bytes32 => uint256) private lastVoteTime; // hash(voter, recipient) => timestamp
    mapping(uint256 => Interaction) private interactions;
    
    address[] private registeredUsers;
    uint256[] private allVoteIds;

    // Events
    event UserRegistered(address indexed user, uint256 timestamp);
    event VoteCast(uint256 indexed voteId, address indexed voter, address indexed recipient, VoteType voteType);
    event ReputationUpdated(address indexed user, int256 newScore, uint256 upvotes, uint256 downvotes);
    event CommentAdded(uint256 indexed voteId, address indexed voter, address indexed recipient, string comment);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyRegistered() {
        require(isRegistered[msg.sender], "User not registered");
        _;
    }

    modifier userExists(address user) {
        require(isRegistered[user], "User does not exist");
        _;
    }

    modifier cannotVoteSelf() {
        require(msg.sender != msg.sender, "Cannot vote for yourself");
        _;
    }

    constructor() {
        owner = msg.sender;
        voteCounter = 0;
        interactionCounter = 0;
    }

    /**
     * @dev Register a new user
     */
    function register() public {
        require(!isRegistered[msg.sender], "User already registered");

        UserReputation storage newUser = userReputations[msg.sender];
        newUser.user = msg.sender;
        newUser.score = 0;
        newUser.upvotes = 0;
        newUser.downvotes = 0;
        newUser.totalVotesReceived = 0;
        newUser.totalVotesGiven = 0;
        newUser.registeredAt = block.timestamp;

        isRegistered[msg.sender] = true;
        registeredUsers.push(msg.sender);

        emit UserRegistered(msg.sender, block.timestamp);
    }

    /**
     * @dev Upvote a user
     * @param recipient User to upvote
     * @param comment Optional comment
     * @return voteId ID of the vote
     */
    function upvote(address recipient, string memory comment) 
        public 
        onlyRegistered 
        userExists(recipient)
        returns (uint256) 
    {
        require(recipient != msg.sender, "Cannot vote for yourself");
        
        bytes32 voteHash = _getVoteHash(msg.sender, recipient);
        require(
            !hasVoted[voteHash] || 
            block.timestamp >= lastVoteTime[voteHash] + COOLDOWN_PERIOD,
            "Cooldown period not elapsed"
        );

        voteCounter++;
        uint256 voteId = voteCounter;

        Vote storage newVote = votes[voteId];
        newVote.id = voteId;
        newVote.voter = msg.sender;
        newVote.recipient = recipient;
        newVote.voteType = VoteType.Upvote;
        newVote.comment = comment;
        newVote.timestamp = block.timestamp;

        votesReceived[recipient].push(voteId);
        votesGiven[msg.sender].push(voteId);
        allVoteIds.push(voteId);

        // Update reputation
        userReputations[recipient].score += UPVOTE_POINTS;
        userReputations[recipient].upvotes++;
        userReputations[recipient].totalVotesReceived++;
        userReputations[msg.sender].totalVotesGiven++;

        // Update vote tracking
        hasVoted[voteHash] = true;
        lastVoteTime[voteHash] = block.timestamp;

        emit VoteCast(voteId, msg.sender, recipient, VoteType.Upvote);
        emit ReputationUpdated(
            recipient, 
            userReputations[recipient].score,
            userReputations[recipient].upvotes,
            userReputations[recipient].downvotes
        );

        if (bytes(comment).length > 0) {
            emit CommentAdded(voteId, msg.sender, recipient, comment);
        }

        return voteId;
    }

    /**
     * @dev Downvote a user
     * @param recipient User to downvote
     * @param comment Optional comment
     * @return voteId ID of the vote
     */
    function downvote(address recipient, string memory comment) 
        public 
        onlyRegistered 
        userExists(recipient)
        returns (uint256) 
    {
        require(recipient != msg.sender, "Cannot vote for yourself");
        
        bytes32 voteHash = _getVoteHash(msg.sender, recipient);
        require(
            !hasVoted[voteHash] || 
            block.timestamp >= lastVoteTime[voteHash] + COOLDOWN_PERIOD,
            "Cooldown period not elapsed"
        );

        voteCounter++;
        uint256 voteId = voteCounter;

        Vote storage newVote = votes[voteId];
        newVote.id = voteId;
        newVote.voter = msg.sender;
        newVote.recipient = recipient;
        newVote.voteType = VoteType.Downvote;
        newVote.comment = comment;
        newVote.timestamp = block.timestamp;

        votesReceived[recipient].push(voteId);
        votesGiven[msg.sender].push(voteId);
        allVoteIds.push(voteId);

        // Update reputation
        userReputations[recipient].score += DOWNVOTE_POINTS;
        userReputations[recipient].downvotes++;
        userReputations[recipient].totalVotesReceived++;
        userReputations[msg.sender].totalVotesGiven++;

        // Update vote tracking
        hasVoted[voteHash] = true;
        lastVoteTime[voteHash] = block.timestamp;

        emit VoteCast(voteId, msg.sender, recipient, VoteType.Downvote);
        emit ReputationUpdated(
            recipient, 
            userReputations[recipient].score,
            userReputations[recipient].upvotes,
            userReputations[recipient].downvotes
        );

        if (bytes(comment).length > 0) {
            emit CommentAdded(voteId, msg.sender, recipient, comment);
        }

        return voteId;
    }

    /**
     * @dev Get vote hash for cooldown tracking
     * @param voter Voter address
     * @param recipient Recipient address
     * @return Hash of voter and recipient
     */
    function _getVoteHash(address voter, address recipient) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(voter, recipient));
    }

    /**
     * @dev Check if user can vote for another user
     * @param voter Voter address
     * @param recipient Recipient address
     * @return true if can vote
     */
    function canVote(address voter, address recipient) public view returns (bool) {
        if (!isRegistered[voter] || !isRegistered[recipient]) {
            return false;
        }
        
        if (voter == recipient) {
            return false;
        }

        bytes32 voteHash = _getVoteHash(voter, recipient);
        if (!hasVoted[voteHash]) {
            return true;
        }

        return block.timestamp >= lastVoteTime[voteHash] + COOLDOWN_PERIOD;
    }

    /**
     * @dev Get time until next vote allowed
     * @param voter Voter address
     * @param recipient Recipient address
     * @return Seconds until next vote (0 if can vote now)
     */
    function getTimeUntilNextVote(address voter, address recipient) public view returns (uint256) {
        bytes32 voteHash = _getVoteHash(voter, recipient);
        
        if (!hasVoted[voteHash]) {
            return 0;
        }

        uint256 nextVoteTime = lastVoteTime[voteHash] + COOLDOWN_PERIOD;
        if (block.timestamp >= nextVoteTime) {
            return 0;
        }

        return nextVoteTime - block.timestamp;
    }

    /**
     * @dev Get user reputation
     * @param user User address
     * @return UserReputation details
     */
    function getUserReputation(address user) 
        public 
        view 
        userExists(user)
        returns (UserReputation memory) 
    {
        return userReputations[user];
    }

    /**
     * @dev Get user reputation score
     * @param user User address
     * @return Reputation score
     */
    function getReputationScore(address user) 
        public 
        view 
        userExists(user)
        returns (int256) 
    {
        return userReputations[user].score;
    }

    /**
     * @dev Get vote details
     * @param voteId Vote ID
     * @return Vote details
     */
    function getVote(uint256 voteId) public view returns (Vote memory) {
        require(voteId > 0 && voteId <= voteCounter, "Vote does not exist");
        return votes[voteId];
    }

    /**
     * @dev Get votes received by user
     * @param user User address
     * @return Array of vote IDs
     */
    function getVotesReceived(address user) 
        public 
        view 
        userExists(user)
        returns (uint256[] memory) 
    {
        return votesReceived[user];
    }

    /**
     * @dev Get votes given by user
     * @param user User address
     * @return Array of vote IDs
     */
    function getVotesGiven(address user) 
        public 
        view 
        userExists(user)
        returns (uint256[] memory) 
    {
        return votesGiven[user];
    }

    /**
     * @dev Get all votes
     * @return Array of all votes
     */
    function getAllVotes() public view returns (Vote[] memory) {
        Vote[] memory allVotes = new Vote[](allVoteIds.length);
        
        for (uint256 i = 0; i < allVoteIds.length; i++) {
            allVotes[i] = votes[allVoteIds[i]];
        }
        
        return allVotes;
    }

    /**
     * @dev Get upvotes received by user
     * @param user User address
     * @return Array of upvote details
     */
    function getUpvotesReceived(address user) 
        public 
        view 
        userExists(user)
        returns (Vote[] memory) 
    {
        uint256[] memory userVotes = votesReceived[user];
        uint256 count = 0;

        for (uint256 i = 0; i < userVotes.length; i++) {
            if (votes[userVotes[i]].voteType == VoteType.Upvote) {
                count++;
            }
        }

        Vote[] memory result = new Vote[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < userVotes.length; i++) {
            Vote memory vote = votes[userVotes[i]];
            if (vote.voteType == VoteType.Upvote) {
                result[index] = vote;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get downvotes received by user
     * @param user User address
     * @return Array of downvote details
     */
    function getDownvotesReceived(address user) 
        public 
        view 
        userExists(user)
        returns (Vote[] memory) 
    {
        uint256[] memory userVotes = votesReceived[user];
        uint256 count = 0;

        for (uint256 i = 0; i < userVotes.length; i++) {
            if (votes[userVotes[i]].voteType == VoteType.Downvote) {
                count++;
            }
        }

        Vote[] memory result = new Vote[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < userVotes.length; i++) {
            Vote memory vote = votes[userVotes[i]];
            if (vote.voteType == VoteType.Downvote) {
                result[index] = vote;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get all registered users
     * @return Array of user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return registeredUsers;
    }

    /**
     * @dev Get all user reputations
     * @return Array of UserReputation details
     */
    function getAllUserReputations() public view returns (UserReputation[] memory) {
        UserReputation[] memory allReputations = new UserReputation[](registeredUsers.length);
        
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            allReputations[i] = userReputations[registeredUsers[i]];
        }
        
        return allReputations;
    }

    /**
     * @dev Get top users by reputation score
     * @param count Number of top users to return
     * @return Array of user addresses sorted by score
     */
    function getTopUsers(uint256 count) public view returns (address[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > registeredUsers.length ? registeredUsers.length : count;
        address[] memory sortedUsers = new address[](registeredUsers.length);
        
        // Copy users
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            sortedUsers[i] = registeredUsers[i];
        }

        // Sort by score (bubble sort for simplicity)
        for (uint256 i = 0; i < sortedUsers.length; i++) {
            for (uint256 j = i + 1; j < sortedUsers.length; j++) {
                if (userReputations[sortedUsers[i]].score < userReputations[sortedUsers[j]].score) {
                    address temp = sortedUsers[i];
                    sortedUsers[i] = sortedUsers[j];
                    sortedUsers[j] = temp;
                }
            }
        }

        // Return top count
        address[] memory result = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = sortedUsers[i];
        }

        return result;
    }

    /**
     * @dev Get users with positive reputation
     * @return Array of user addresses
     */
    function getPositiveReputationUsers() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            if (userReputations[registeredUsers[i]].score > 0) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < registeredUsers.length; i++) {
            address user = registeredUsers[i];
            if (userReputations[user].score > 0) {
                result[index] = user;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get users with negative reputation
     * @return Array of user addresses
     */
    function getNegativeReputationUsers() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            if (userReputations[registeredUsers[i]].score < 0) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < registeredUsers.length; i++) {
            address user = registeredUsers[i];
            if (userReputations[user].score < 0) {
                result[index] = user;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total number of registered users
     * @return Total user count
     */
    function getTotalUsers() public view returns (uint256) {
        return registeredUsers.length;
    }

    /**
     * @dev Get total number of votes
     * @return Total vote count
     */
    function getTotalVotes() public view returns (uint256) {
        return voteCounter;
    }

    /**
     * @dev Get total upvotes in system
     * @return Total upvote count
     */
    function getTotalUpvotes() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allVoteIds.length; i++) {
            if (votes[allVoteIds[i]].voteType == VoteType.Upvote) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get total downvotes in system
     * @return Total downvote count
     */
    function getTotalDownvotes() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allVoteIds.length; i++) {
            if (votes[allVoteIds[i]].voteType == VoteType.Downvote) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get reputation percentage (upvotes / total votes)
     * @param user User address
     * @return Percentage (0-100)
     */
    function getReputationPercentage(address user) 
        public 
        view 
        userExists(user)
        returns (uint256) 
    {
        UserReputation memory rep = userReputations[user];
        
        if (rep.totalVotesReceived == 0) {
            return 0;
        }

        return (rep.upvotes * 100) / rep.totalVotesReceived;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }
}
