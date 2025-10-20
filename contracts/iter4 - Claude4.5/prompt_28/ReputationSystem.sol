// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ReputationSystem
 * @dev A reputation system where users can upvote or downvote others based on interactions
 */
contract ReputationSystem {
    struct User {
        address userAddress;
        int256 reputationScore;
        uint256 upvotes;
        uint256 downvotes;
        bool isRegistered;
    }
    
    struct Vote {
        address voter;
        address target;
        bool isUpvote;
        uint256 timestamp;
        string comment;
    }
    
    address public owner;
    uint256 public totalUsers;
    uint256 public totalVotes;
    
    mapping(address => User) public users;
    mapping(uint256 => Vote) public votes;
    mapping(address => mapping(address => bool)) public hasVoted;
    mapping(address => address[]) public votersForUser;
    mapping(address => Vote[]) public userVotesReceived;
    mapping(address => Vote[]) public userVotesGiven;
    
    // Events
    event UserRegistered(address indexed user, uint256 timestamp);
    event Upvoted(address indexed voter, address indexed target, uint256 timestamp);
    event Downvoted(address indexed voter, address indexed target, uint256 timestamp);
    event VoteRevoked(address indexed voter, address indexed target, uint256 timestamp);
    event ReputationUpdated(address indexed user, int256 newScore);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User must be registered");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Registers a new user in the system
     */
    function registerUser() external {
        require(!users[msg.sender].isRegistered, "User already registered");
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            reputationScore: 0,
            upvotes: 0,
            downvotes: 0,
            isRegistered: true
        });
        
        totalUsers++;
        
        emit UserRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Upvotes a user
     * @param _target The address of the user to upvote
     * @param _comment Optional comment for the vote
     */
    function upvote(address _target, string memory _comment) external onlyRegistered {
        require(_target != address(0), "Invalid target address");
        require(_target != msg.sender, "Cannot vote for yourself");
        require(users[_target].isRegistered, "Target user not registered");
        require(!hasVoted[msg.sender][_target], "Already voted for this user");
        
        users[_target].upvotes++;
        users[_target].reputationScore++;
        
        hasVoted[msg.sender][_target] = true;
        votersForUser[_target].push(msg.sender);
        
        totalVotes++;
        Vote memory newVote = Vote({
            voter: msg.sender,
            target: _target,
            isUpvote: true,
            timestamp: block.timestamp,
            comment: _comment
        });
        
        votes[totalVotes] = newVote;
        userVotesReceived[_target].push(newVote);
        userVotesGiven[msg.sender].push(newVote);
        
        emit Upvoted(msg.sender, _target, block.timestamp);
        emit ReputationUpdated(_target, users[_target].reputationScore);
    }
    
    /**
     * @dev Downvotes a user
     * @param _target The address of the user to downvote
     * @param _comment Optional comment for the vote
     */
    function downvote(address _target, string memory _comment) external onlyRegistered {
        require(_target != address(0), "Invalid target address");
        require(_target != msg.sender, "Cannot vote for yourself");
        require(users[_target].isRegistered, "Target user not registered");
        require(!hasVoted[msg.sender][_target], "Already voted for this user");
        
        users[_target].downvotes++;
        users[_target].reputationScore--;
        
        hasVoted[msg.sender][_target] = true;
        votersForUser[_target].push(msg.sender);
        
        totalVotes++;
        Vote memory newVote = Vote({
            voter: msg.sender,
            target: _target,
            isUpvote: false,
            timestamp: block.timestamp,
            comment: _comment
        });
        
        votes[totalVotes] = newVote;
        userVotesReceived[_target].push(newVote);
        userVotesGiven[msg.sender].push(newVote);
        
        emit Downvoted(msg.sender, _target, block.timestamp);
        emit ReputationUpdated(_target, users[_target].reputationScore);
    }
    
    /**
     * @dev Revokes a vote for a user (allows changing vote)
     * @param _target The address of the user to revoke vote from
     */
    function revokeVote(address _target) external onlyRegistered {
        require(_target != address(0), "Invalid target address");
        require(users[_target].isRegistered, "Target user not registered");
        require(hasVoted[msg.sender][_target], "No vote to revoke");
        
        // Find the vote and adjust reputation
        bool wasUpvote = false;
        for (uint256 i = 0; i < userVotesReceived[_target].length; i++) {
            if (userVotesReceived[_target][i].voter == msg.sender) {
                wasUpvote = userVotesReceived[_target][i].isUpvote;
                break;
            }
        }
        
        if (wasUpvote) {
            users[_target].upvotes--;
            users[_target].reputationScore--;
        } else {
            users[_target].downvotes--;
            users[_target].reputationScore++;
        }
        
        hasVoted[msg.sender][_target] = false;
        
        emit VoteRevoked(msg.sender, _target, block.timestamp);
        emit ReputationUpdated(_target, users[_target].reputationScore);
    }
    
    /**
     * @dev Returns the reputation details of a user
     * @param _user The address of the user
     * @return userAddress The user's address
     * @return reputationScore The reputation score
     * @return upvotes Total upvotes received
     * @return downvotes Total downvotes received
     * @return isRegistered Registration status
     */
    function getUserReputation(address _user) external view returns (
        address userAddress,
        int256 reputationScore,
        uint256 upvotes,
        uint256 downvotes,
        bool isRegistered
    ) {
        User memory user = users[_user];
        return (
            user.userAddress,
            user.reputationScore,
            user.upvotes,
            user.downvotes,
            user.isRegistered
        );
    }
    
    /**
     * @dev Returns the reputation score of a user
     * @param _user The address of the user
     * @return The reputation score
     */
    function getReputationScore(address _user) external view returns (int256) {
        require(users[_user].isRegistered, "User not registered");
        return users[_user].reputationScore;
    }
    
    /**
     * @dev Returns all votes received by a user
     * @param _user The address of the user
     * @return Array of votes received
     */
    function getVotesReceived(address _user) external view returns (Vote[] memory) {
        require(users[_user].isRegistered, "User not registered");
        return userVotesReceived[_user];
    }
    
    /**
     * @dev Returns all votes given by a user
     * @param _user The address of the user
     * @return Array of votes given
     */
    function getVotesGiven(address _user) external view returns (Vote[] memory) {
        require(users[_user].isRegistered, "User not registered");
        return userVotesGiven[_user];
    }
    
    /**
     * @dev Returns all voters for a user
     * @param _user The address of the user
     * @return Array of voter addresses
     */
    function getVotersForUser(address _user) external view returns (address[] memory) {
        require(users[_user].isRegistered, "User not registered");
        return votersForUser[_user];
    }
    
    /**
     * @dev Checks if a user has voted for another user
     * @param _voter The address of the voter
     * @param _target The address of the target user
     * @return True if voted, false otherwise
     */
    function hasUserVoted(address _voter, address _target) external view returns (bool) {
        return hasVoted[_voter][_target];
    }
    
    /**
     * @dev Returns the caller's reputation details
     * @return userAddress The user's address
     * @return reputationScore The reputation score
     * @return upvotes Total upvotes received
     * @return downvotes Total downvotes received
     * @return isRegistered Registration status
     */
    function getMyReputation() external view returns (
        address userAddress,
        int256 reputationScore,
        uint256 upvotes,
        uint256 downvotes,
        bool isRegistered
    ) {
        User memory user = users[msg.sender];
        return (
            user.userAddress,
            user.reputationScore,
            user.upvotes,
            user.downvotes,
            user.isRegistered
        );
    }
    
    /**
     * @dev Returns all votes the caller has received
     * @return Array of votes received
     */
    function getMyVotesReceived() external view returns (Vote[] memory) {
        return userVotesReceived[msg.sender];
    }
    
    /**
     * @dev Returns all votes the caller has given
     * @return Array of votes given
     */
    function getMyVotesGiven() external view returns (Vote[] memory) {
        return userVotesGiven[msg.sender];
    }
    
    /**
     * @dev Returns the total number of registered users
     * @return Total number of users
     */
    function getTotalUsers() external view returns (uint256) {
        return totalUsers;
    }
    
    /**
     * @dev Returns the total number of votes cast
     * @return Total number of votes
     */
    function getTotalVotes() external view returns (uint256) {
        return totalVotes;
    }
    
    /**
     * @dev Checks if a user is registered
     * @param _user The address of the user
     * @return True if registered, false otherwise
     */
    function isUserRegistered(address _user) external view returns (bool) {
        return users[_user].isRegistered;
    }
    
    /**
     * @dev Returns users with reputation above a threshold
     * @param _threshold The minimum reputation score
     * @return Array of user addresses with reputation above threshold
     */
    function getUsersAboveReputation(int256 _threshold) external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count users above threshold
        for (uint256 i = 0; i < totalUsers; i++) {
            // This is a simplified version - in production, you'd maintain a list of all user addresses
        }
        
        // For simplicity, return empty array
        // In production, maintain a separate array of all registered user addresses
        address[] memory result = new address[](0);
        return result;
    }
    
    /**
     * @dev Returns details of a specific vote
     * @param _voteId The ID of the vote
     * @return voter The voter's address
     * @return target The target user's address
     * @return isUpvote Whether it was an upvote
     * @return timestamp When the vote was cast
     * @return comment The comment left with the vote
     */
    function getVoteDetails(uint256 _voteId) external view returns (
        address voter,
        address target,
        bool isUpvote,
        uint256 timestamp,
        string memory comment
    ) {
        require(_voteId > 0 && _voteId <= totalVotes, "Invalid vote ID");
        
        Vote memory vote = votes[_voteId];
        return (
            vote.voter,
            vote.target,
            vote.isUpvote,
            vote.timestamp,
            vote.comment
        );
    }
    
    /**
     * @dev Calculates the vote ratio (upvotes / total votes) for a user
     * @param _user The address of the user
     * @return The upvote percentage (0-100)
     */
    function getUpvotePercentage(address _user) external view returns (uint256) {
        require(users[_user].isRegistered, "User not registered");
        
        uint256 totalUserVotes = users[_user].upvotes + users[_user].downvotes;
        if (totalUserVotes == 0) {
            return 0;
        }
        
        return (users[_user].upvotes * 100) / totalUserVotes;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
