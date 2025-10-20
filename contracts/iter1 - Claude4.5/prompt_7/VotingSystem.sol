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
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }
    
    uint256 private pollCounter;
    mapping(uint256 => Poll) public polls;
    
    event PollCreated(
        uint256 indexed pollId,
        string question,
        uint256 optionsCount,
        uint256 endTime
    );
    
    event VoteCast(
        uint256 indexed pollId,
        address indexed voter,
        uint256 optionIndex
    );
    
    event PollEnded(uint256 indexed pollId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new poll
     * @param question The poll question
     * @param options Array of voting options
     * @param durationInMinutes Duration of the poll in minutes
     * @return pollId The ID of the created poll
     */
    function createPoll(
        string memory question,
        string[] memory options,
        uint256 durationInMinutes
    ) external onlyOwner returns (uint256) {
        require(bytes(question).length > 0, "Question cannot be empty");
        require(options.length >= 2, "Must have at least 2 options");
        require(durationInMinutes > 0, "Duration must be greater than 0");
        
        pollCounter++;
        uint256 pollId = pollCounter;
        
        Poll storage newPoll = polls[pollId];
        newPoll.id = pollId;
        newPoll.question = question;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = block.timestamp + (durationInMinutes * 1 minutes);
        newPoll.isActive = true;
        newPoll.totalVotes = 0;
        
        for (uint256 i = 0; i < options.length; i++) {
            require(bytes(options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(options[i]);
        }
        
        emit PollCreated(pollId, question, options.length, newPoll.endTime);
        
        return pollId;
    }
    
    /**
     * @dev Cast a vote for a poll
     * @param pollId The ID of the poll
     * @param optionIndex The index of the chosen option
     */
    function vote(uint256 pollId, uint256 optionIndex) external {
        Poll storage poll = polls[pollId];
        
        require(poll.id != 0, "Poll does not exist");
        require(poll.isActive, "Poll is not active");
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
        Poll storage poll = polls[pollId];
        
        require(poll.id != 0, "Poll does not exist");
        require(poll.isActive, "Poll is already ended");
        
        poll.isActive = false;
        
        emit PollEnded(pollId);
    }
    
    /**
     * @dev Get poll details
     * @param pollId The ID of the poll
     * @return question The poll question
     * @return options Array of voting options
     * @return totalVotes Total number of votes
     * @return startTime Poll start time
     * @return endTime Poll end time
     * @return isActive Whether the poll is active
     */
    function getPollDetails(uint256 pollId) external view returns (
        string memory question,
        string[] memory options,
        uint256 totalVotes,
        uint256 startTime,
        uint256 endTime,
        bool isActive
    ) {
        Poll storage poll = polls[pollId];
        require(poll.id != 0, "Poll does not exist");
        
        return (
            poll.question,
            poll.options,
            poll.totalVotes,
            poll.startTime,
            poll.endTime,
            poll.isActive && block.timestamp < poll.endTime
        );
    }
    
    /**
     * @dev Get vote count for a specific option
     * @param pollId The ID of the poll
     * @param optionIndex The index of the option
     * @return The number of votes for the option
     */
    function getVoteCount(uint256 pollId, uint256 optionIndex) external view returns (uint256) {
        Poll storage poll = polls[pollId];
        require(poll.id != 0, "Poll does not exist");
        require(optionIndex < poll.options.length, "Invalid option index");
        
        return poll.voteCounts[optionIndex];
    }
    
    /**
     * @dev Get all vote counts for a poll
     * @param pollId The ID of the poll
     * @return Array of vote counts for each option
     */
    function getAllVoteCounts(uint256 pollId) external view returns (uint256[] memory) {
        Poll storage poll = polls[pollId];
        require(poll.id != 0, "Poll does not exist");
        
        uint256[] memory counts = new uint256[](poll.options.length);
        for (uint256 i = 0; i < poll.options.length; i++) {
            counts[i] = poll.voteCounts[i];
        }
        
        return counts;
    }
    
    /**
     * @dev Check if an address has voted in a poll
     * @param pollId The ID of the poll
     * @param voter The address to check
     * @return Whether the address has voted
     */
    function hasVoted(uint256 pollId, address voter) external view returns (bool) {
        Poll storage poll = polls[pollId];
        require(poll.id != 0, "Poll does not exist");
        
        return poll.hasVoted[voter];
    }
    
    /**
     * @dev Get the choice of a voter in a poll
     * @param pollId The ID of the poll
     * @param voter The address of the voter
     * @return The option index chosen by the voter
     */
    function getVoterChoice(uint256 pollId, address voter) external view returns (uint256) {
        Poll storage poll = polls[pollId];
        require(poll.id != 0, "Poll does not exist");
        require(poll.hasVoted[voter], "Voter has not voted in this poll");
        
        return poll.voterChoice[voter];
    }
    
    /**
     * @dev Get the total number of polls created
     * @return The total number of polls
     */
    function getTotalPolls() external view returns (uint256) {
        return pollCounter;
    }
    
    /**
     * @dev Get the winning option(s) of a poll
     * @param pollId The ID of the poll
     * @return The index of the winning option
     * @return The number of votes for the winning option
     */
    function getWinningOption(uint256 pollId) external view returns (uint256, uint256) {
        Poll storage poll = polls[pollId];
        require(poll.id != 0, "Poll does not exist");
        require(block.timestamp >= poll.endTime || !poll.isActive, "Poll is still active");
        
        uint256 winningOptionIndex = 0;
        uint256 maxVotes = poll.voteCounts[0];
        
        for (uint256 i = 1; i < poll.options.length; i++) {
            if (poll.voteCounts[i] > maxVotes) {
                maxVotes = poll.voteCounts[i];
                winningOptionIndex = i;
            }
        }
        
        return (winningOptionIndex, maxVotes);
    }
}
