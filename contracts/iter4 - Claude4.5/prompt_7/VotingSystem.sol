// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingSystem
 * @dev A simple voting system where the owner can start polls and users can vote for predefined options
 */
contract VotingSystem {
    address public owner;
    
    struct Poll {
        uint256 id;
        string question;
        string[] options;
        mapping(uint256 => uint256) votes;
        mapping(address => bool) hasVoted;
        uint256 totalVotes;
        bool isActive;
        uint256 startTime;
        uint256 endTime;
    }
    
    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    
    // Events
    event PollCreated(uint256 indexed pollId, string question, uint256 optionCount, uint256 endTime);
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 optionIndex);
    event PollEnded(uint256 indexed pollId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Creates a new poll with predefined options
     * @param _question The poll question
     * @param _options Array of voting options
     * @param _durationInDays Duration of the poll in days
     */
    function createPoll(
        string memory _question,
        string[] memory _options,
        uint256 _durationInDays
    ) external onlyOwner {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(_options.length >= 2, "Must have at least 2 options");
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        pollCount++;
        Poll storage newPoll = polls[pollCount];
        
        newPoll.id = pollCount;
        newPoll.question = _question;
        newPoll.isActive = true;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = block.timestamp + (_durationInDays * 1 days);
        newPoll.totalVotes = 0;
        
        for (uint256 i = 0; i < _options.length; i++) {
            require(bytes(_options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(_options[i]);
        }
        
        emit PollCreated(pollCount, _question, _options.length, newPoll.endTime);
    }
    
    /**
     * @dev Allows a user to vote on an active poll
     * @param _pollId The ID of the poll
     * @param _optionIndex The index of the option to vote for
     */
    function vote(uint256 _pollId, uint256 _optionIndex) external {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        require(poll.isActive, "Poll is not active");
        require(block.timestamp < poll.endTime, "Poll has ended");
        require(!poll.hasVoted[msg.sender], "Already voted in this poll");
        require(_optionIndex < poll.options.length, "Invalid option index");
        
        poll.hasVoted[msg.sender] = true;
        poll.votes[_optionIndex]++;
        poll.totalVotes++;
        
        emit VoteCast(_pollId, msg.sender, _optionIndex);
    }
    
    /**
     * @dev Allows the owner to end a poll manually
     * @param _pollId The ID of the poll to end
     */
    function endPoll(uint256 _pollId) external onlyOwner {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        require(poll.isActive, "Poll is already ended");
        
        poll.isActive = false;
        
        emit PollEnded(_pollId);
    }
    
    /**
     * @dev Returns the details of a poll
     * @param _pollId The ID of the poll
     * @return question The poll question
     * @return options Array of options
     * @return totalVotes Total number of votes
     * @return isActive Whether the poll is active
     * @return endTime When the poll ends
     */
    function getPollDetails(uint256 _pollId) external view returns (
        string memory question,
        string[] memory options,
        uint256 totalVotes,
        bool isActive,
        uint256 endTime
    ) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        return (
            poll.question,
            poll.options,
            poll.totalVotes,
            poll.isActive,
            poll.endTime
        );
    }
    
    /**
     * @dev Returns the vote count for a specific option
     * @param _pollId The ID of the poll
     * @param _optionIndex The index of the option
     * @return The number of votes for the option
     */
    function getVoteCount(uint256 _pollId, uint256 _optionIndex) external view returns (uint256) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        require(_optionIndex < polls[_pollId].options.length, "Invalid option index");
        
        return polls[_pollId].votes[_optionIndex];
    }
    
    /**
     * @dev Returns all vote counts for a poll
     * @param _pollId The ID of the poll
     * @return Array of vote counts for each option
     */
    function getAllVoteCounts(uint256 _pollId) external view returns (uint256[] memory) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        uint256[] memory voteCounts = new uint256[](poll.options.length);
        
        for (uint256 i = 0; i < poll.options.length; i++) {
            voteCounts[i] = poll.votes[i];
        }
        
        return voteCounts;
    }
    
    /**
     * @dev Checks if an address has voted in a specific poll
     * @param _pollId The ID of the poll
     * @param _voter The address to check
     * @return True if the address has voted, false otherwise
     */
    function hasVotedInPoll(uint256 _pollId, address _voter) external view returns (bool) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        return polls[_pollId].hasVoted[_voter];
    }
    
    /**
     * @dev Returns the winning option index for a poll
     * @param _pollId The ID of the poll
     * @return The index of the winning option
     */
    function getWinningOption(uint256 _pollId) external view returns (uint256) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        require(poll.options.length > 0, "No options in poll");
        
        uint256 winningVoteCount = 0;
        uint256 winningIndex = 0;
        
        for (uint256 i = 0; i < poll.options.length; i++) {
            if (poll.votes[i] > winningVoteCount) {
                winningVoteCount = poll.votes[i];
                winningIndex = i;
            }
        }
        
        return winningIndex;
    }
}
