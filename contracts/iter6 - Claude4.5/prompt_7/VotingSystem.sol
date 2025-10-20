// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingSystem
 * @dev A simple voting system where the owner can start a poll and users can vote for predefined options
 */
contract VotingSystem {
    address public owner;
    
    struct Poll {
        uint256 id;
        string question;
        string[] options;
        mapping(uint256 => uint256) voteCounts;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voterChoice;
        uint256 totalVotes;
        bool isActive;
        uint256 startTime;
        uint256 endTime;
    }
    
    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    
    // Events
    event PollCreated(uint256 indexed pollId, string question, uint256 optionsCount);
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 optionIndex);
    event PollEnded(uint256 indexed pollId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new poll
     * @param question The poll question
     * @param options Array of option strings
     * @param duration Duration of the poll in seconds (0 for unlimited)
     */
    function createPoll(string memory question, string[] memory options, uint256 duration) external onlyOwner {
        require(bytes(question).length > 0, "Question cannot be empty");
        require(options.length >= 2, "Must have at least 2 options");
        
        pollCount++;
        Poll storage newPoll = polls[pollCount];
        
        newPoll.id = pollCount;
        newPoll.question = question;
        newPoll.isActive = true;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = duration > 0 ? block.timestamp + duration : 0;
        newPoll.totalVotes = 0;
        
        for (uint256 i = 0; i < options.length; i++) {
            require(bytes(options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(options[i]);
        }
        
        emit PollCreated(pollCount, question, options.length);
    }
    
    /**
     * @dev Cast a vote for a poll option
     * @param pollId The ID of the poll
     * @param optionIndex The index of the option to vote for
     */
    function vote(uint256 pollId, uint256 optionIndex) external {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        Poll storage poll = polls[pollId];
        
        require(poll.isActive, "Poll is not active");
        require(poll.endTime == 0 || block.timestamp <= poll.endTime, "Poll has ended");
        require(!poll.hasVoted[msg.sender], "Already voted in this poll");
        require(optionIndex < poll.options.length, "Invalid option index");
        
        poll.hasVoted[msg.sender] = true;
        poll.voterChoice[msg.sender] = optionIndex;
        poll.voteCounts[optionIndex]++;
        poll.totalVotes++;
        
        emit VoteCast(pollId, msg.sender, optionIndex);
    }
    
    /**
     * @dev End a poll manually
     * @param pollId The ID of the poll to end
     */
    function endPoll(uint256 pollId) external onlyOwner {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        Poll storage poll = polls[pollId];
        
        require(poll.isActive, "Poll is already ended");
        
        poll.isActive = false;
        
        emit PollEnded(pollId);
    }
    
    /**
     * @dev Get poll results
     * @param pollId The ID of the poll
     * @return question The poll question
     * @return options Array of option strings
     * @return voteCounts Array of vote counts for each option
     * @return totalVotes Total number of votes
     * @return isActive Whether the poll is active
     */
    function getPollResults(uint256 pollId) external view returns (
        string memory question,
        string[] memory options,
        uint256[] memory voteCounts,
        uint256 totalVotes,
        bool isActive
    ) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        Poll storage poll = polls[pollId];
        
        uint256[] memory counts = new uint256[](poll.options.length);
        for (uint256 i = 0; i < poll.options.length; i++) {
            counts[i] = poll.voteCounts[i];
        }
        
        return (
            poll.question,
            poll.options,
            counts,
            poll.totalVotes,
            poll.isActive
        );
    }
    
    /**
     * @dev Check if an address has voted in a poll
     * @param pollId The ID of the poll
     * @param voter The address to check
     * @return True if the address has voted, false otherwise
     */
    function hasVotedInPoll(uint256 pollId, address voter) external view returns (bool) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        return polls[pollId].hasVoted[voter];
    }
    
    /**
     * @dev Get the choice of a voter in a poll
     * @param pollId The ID of the poll
     * @param voter The address of the voter
     * @return The option index the voter chose
     */
    function getVoterChoice(uint256 pollId, address voter) external view returns (uint256) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        require(polls[pollId].hasVoted[voter], "Voter has not voted in this poll");
        return polls[pollId].voterChoice[voter];
    }
    
    /**
     * @dev Get poll information
     * @param pollId The ID of the poll
     * @return question The poll question
     * @return optionsCount Number of options
     * @return totalVotes Total votes cast
     * @return isActive Whether the poll is active
     * @return startTime When the poll started
     * @return endTime When the poll ends (0 for unlimited)
     */
    function getPollInfo(uint256 pollId) external view returns (
        string memory question,
        uint256 optionsCount,
        uint256 totalVotes,
        bool isActive,
        uint256 startTime,
        uint256 endTime
    ) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        Poll storage poll = polls[pollId];
        
        return (
            poll.question,
            poll.options.length,
            poll.totalVotes,
            poll.isActive,
            poll.startTime,
            poll.endTime
        );
    }
    
    /**
     * @dev Get all options for a poll
     * @param pollId The ID of the poll
     * @return Array of option strings
     */
    function getPollOptions(uint256 pollId) external view returns (string[] memory) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        return polls[pollId].options;
    }
    
    /**
     * @dev Get vote count for a specific option
     * @param pollId The ID of the poll
     * @param optionIndex The index of the option
     * @return The number of votes for that option
     */
    function getOptionVoteCount(uint256 pollId, uint256 optionIndex) external view returns (uint256) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        require(optionIndex < polls[pollId].options.length, "Invalid option index");
        return polls[pollId].voteCounts[optionIndex];
    }
}
