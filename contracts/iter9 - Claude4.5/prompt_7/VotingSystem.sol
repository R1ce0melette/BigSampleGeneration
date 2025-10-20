// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    
    struct Poll {
        uint256 id;
        string question;
        string[] options;
        mapping(uint256 => uint256) votes;
        mapping(address => bool) hasVoted;
        bool active;
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
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new poll
     * @param _question The poll question
     * @param _options Array of option strings
     * @param _duration Duration of the poll in seconds
     */
    function createPoll(
        string memory _question,
        string[] memory _options,
        uint256 _duration
    ) external onlyOwner {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(_options.length >= 2, "Must have at least 2 options");
        require(_duration > 0, "Duration must be greater than 0");
        
        pollCount++;
        Poll storage newPoll = polls[pollCount];
        
        newPoll.id = pollCount;
        newPoll.question = _question;
        newPoll.active = true;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = block.timestamp + _duration;
        
        for (uint256 i = 0; i < _options.length; i++) {
            require(bytes(_options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(_options[i]);
        }
        
        emit PollCreated(pollCount, _question, _options.length);
    }
    
    /**
     * @dev Cast a vote on a poll
     * @param _pollId The ID of the poll
     * @param _optionIndex The index of the option to vote for
     */
    function vote(uint256 _pollId, uint256 _optionIndex) external {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        require(poll.active, "Poll is not active");
        require(block.timestamp <= poll.endTime, "Poll has ended");
        require(!poll.hasVoted[msg.sender], "Already voted in this poll");
        require(_optionIndex < poll.options.length, "Invalid option index");
        
        poll.hasVoted[msg.sender] = true;
        poll.votes[_optionIndex]++;
        
        emit VoteCast(_pollId, msg.sender, _optionIndex);
    }
    
    /**
     * @dev End a poll manually
     * @param _pollId The ID of the poll to end
     */
    function endPoll(uint256 _pollId) external onlyOwner {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        require(poll.active, "Poll is already ended");
        
        poll.active = false;
        
        emit PollEnded(_pollId);
    }
    
    /**
     * @dev Get poll details
     * @param _pollId The ID of the poll
     * @return question The poll question
     * @return options Array of option strings
     * @return active Whether the poll is active
     * @return startTime The start timestamp
     * @return endTime The end timestamp
     */
    function getPoll(uint256 _pollId) external view returns (
        string memory question,
        string[] memory options,
        bool active,
        uint256 startTime,
        uint256 endTime
    ) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        return (
            poll.question,
            poll.options,
            poll.active,
            poll.startTime,
            poll.endTime
        );
    }
    
    /**
     * @dev Get vote count for a specific option
     * @param _pollId The ID of the poll
     * @param _optionIndex The index of the option
     * @return The number of votes for that option
     */
    function getVotes(uint256 _pollId, uint256 _optionIndex) external view returns (uint256) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        require(_optionIndex < polls[_pollId].options.length, "Invalid option index");
        
        return polls[_pollId].votes[_optionIndex];
    }
    
    /**
     * @dev Get all votes for a poll
     * @param _pollId The ID of the poll
     * @return An array of vote counts for each option
     */
    function getAllVotes(uint256 _pollId) external view returns (uint256[] memory) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        uint256[] memory voteCounts = new uint256[](poll.options.length);
        
        for (uint256 i = 0; i < poll.options.length; i++) {
            voteCounts[i] = poll.votes[i];
        }
        
        return voteCounts;
    }
    
    /**
     * @dev Check if an address has voted in a poll
     * @param _pollId The ID of the poll
     * @param _voter The address to check
     * @return True if the address has voted, false otherwise
     */
    function hasVotedInPoll(uint256 _pollId, address _voter) external view returns (bool) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        return polls[_pollId].hasVoted[_voter];
    }
    
    /**
     * @dev Get the winning option (or one of them if there's a tie)
     * @param _pollId The ID of the poll
     * @return winningOptionIndex The index of the winning option
     * @return winningVoteCount The number of votes for the winning option
     */
    function getWinner(uint256 _pollId) external view returns (uint256 winningOptionIndex, uint256 winningVoteCount) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        
        Poll storage poll = polls[_pollId];
        
        winningVoteCount = 0;
        winningOptionIndex = 0;
        
        for (uint256 i = 0; i < poll.options.length; i++) {
            if (poll.votes[i] > winningVoteCount) {
                winningVoteCount = poll.votes[i];
                winningOptionIndex = i;
            }
        }
        
        return (winningOptionIndex, winningVoteCount);
    }
}
