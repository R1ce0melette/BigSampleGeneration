// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingSystem
 * @dev A simple voting system where the owner can start a poll and users can vote for predefined options
 */
contract VotingSystem {
    address public owner;
    
    // Poll structure
    struct Poll {
        uint256 id;
        string question;
        string[] options;
        mapping(uint256 => uint256) voteCounts;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voterChoice;
        uint256 totalVotes;
        bool active;
        uint256 startTime;
        uint256 endTime;
    }
    
    // State variables
    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    
    // Events
    event PollCreated(uint256 indexed pollId, string question, uint256 optionsCount, uint256 endTime);
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 option);
    event PollEnded(uint256 indexed pollId);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    /**
     * @dev Constructor sets the contract owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new poll
     * @param question The poll question
     * @param options Array of voting options
     * @param durationInDays Duration of the poll in days
     * @return pollId The ID of the created poll
     */
    function createPoll(
        string memory question,
        string[] memory options,
        uint256 durationInDays
    ) external onlyOwner returns (uint256) {
        require(bytes(question).length > 0, "Question cannot be empty");
        require(options.length >= 2, "Must have at least 2 options");
        require(durationInDays > 0, "Duration must be greater than 0");
        
        pollCount++;
        uint256 pollId = pollCount;
        
        Poll storage newPoll = polls[pollId];
        newPoll.id = pollId;
        newPoll.question = question;
        newPoll.active = true;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = block.timestamp + (durationInDays * 1 days);
        newPoll.totalVotes = 0;
        
        for (uint256 i = 0; i < options.length; i++) {
            require(bytes(options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(options[i]);
        }
        
        emit PollCreated(pollId, question, options.length, newPoll.endTime);
        
        return pollId;
    }
    
    /**
     * @dev Cast a vote for a poll option
     * @param pollId The ID of the poll
     * @param optionIndex The index of the option to vote for
     */
    function vote(uint256 pollId, uint256 optionIndex) external {
        require(pollId > 0 && pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[pollId];
        
        require(poll.active, "Poll is not active");
        require(block.timestamp < poll.endTime, "Poll has ended");
        require(!poll.hasVoted[msg.sender], "Already voted in this poll");
        require(optionIndex < poll.options.length, "Invalid option index");
        
        poll.hasVoted[msg.sender] = true;
        poll.voterChoice[msg.sender] = optionIndex;
        poll.voteCounts[optionIndex]++;
        poll.totalVotes++;
        
        emit VoteCast(pollId, msg.sender, optionIndex);
    }
    
    /**
     * @dev End a poll manually (only owner)
     * @param pollId The ID of the poll to end
     */
    function endPoll(uint256 pollId) external onlyOwner {
        require(pollId > 0 && pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[pollId];
        require(poll.active, "Poll is already ended");
        
        poll.active = false;
        
        emit PollEnded(pollId);
    }
    
    /**
     * @dev Get poll results
     * @param pollId The ID of the poll
     * @return question The poll question
     * @return options The voting options
     * @return voteCounts The vote counts for each option
     * @return totalVotes The total number of votes
     * @return active Whether the poll is active
     */
    function getPollResults(uint256 pollId) external view returns (
        string memory question,
        string[] memory options,
        uint256[] memory voteCounts,
        uint256 totalVotes,
        bool active
    ) {
        require(pollId > 0 && pollId <= pollCount, "Invalid poll ID");
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
            poll.active && block.timestamp < poll.endTime
        );
    }
    
    /**
     * @dev Check if an address has voted in a poll
     * @param pollId The ID of the poll
     * @param voter The address to check
     * @return True if the address has voted, false otherwise
     */
    function hasVotedInPoll(uint256 pollId, address voter) external view returns (bool) {
        require(pollId > 0 && pollId <= pollCount, "Invalid poll ID");
        return polls[pollId].hasVoted[voter];
    }
    
    /**
     * @dev Get the vote choice of an address in a poll
     * @param pollId The ID of the poll
     * @param voter The address to check
     * @return The option index voted for (only valid if hasVoted is true)
     */
    function getVoterChoice(uint256 pollId, address voter) external view returns (uint256) {
        require(pollId > 0 && pollId <= pollCount, "Invalid poll ID");
        require(polls[pollId].hasVoted[voter], "Address has not voted in this poll");
        return polls[pollId].voterChoice[voter];
    }
    
    /**
     * @dev Get poll information
     * @param pollId The ID of the poll
     * @return question The poll question
     * @return optionsCount Number of options
     * @return totalVotes Total votes cast
     * @return active Whether poll is active
     * @return startTime Poll start time
     * @return endTime Poll end time
     */
    function getPollInfo(uint256 pollId) external view returns (
        string memory question,
        uint256 optionsCount,
        uint256 totalVotes,
        bool active,
        uint256 startTime,
        uint256 endTime
    ) {
        require(pollId > 0 && pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[pollId];
        
        return (
            poll.question,
            poll.options.length,
            poll.totalVotes,
            poll.active && block.timestamp < poll.endTime,
            poll.startTime,
            poll.endTime
        );
    }
    
    /**
     * @dev Get the options for a poll
     * @param pollId The ID of the poll
     * @return The array of options
     */
    function getPollOptions(uint256 pollId) external view returns (string[] memory) {
        require(pollId > 0 && pollId <= pollCount, "Invalid poll ID");
        return polls[pollId].options;
    }
}
