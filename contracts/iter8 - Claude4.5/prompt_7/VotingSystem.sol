// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingSystem
 * @dev Simple voting system where owner can start polls and users can vote for predefined options
 */
contract VotingSystem {
    // Poll structure
    struct Poll {
        uint256 pollId;
        string question;
        string[] options;
        mapping(uint256 => uint256) voteCounts;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) userVotes;
        address[] voters;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool exists;
    }

    // State variables
    address public owner;
    uint256 private pollIdCounter;
    mapping(uint256 => Poll) private polls;
    uint256[] private pollIds;

    // Events
    event PollCreated(uint256 indexed pollId, string question, uint256 optionCount, uint256 endTime, uint256 timestamp);
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 optionIndex, uint256 timestamp);
    event PollEnded(uint256 indexed pollId, uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier pollExists(uint256 pollId) {
        require(polls[pollId].exists, "Poll does not exist");
        _;
    }

    modifier pollActive(uint256 pollId) {
        require(polls[pollId].isActive, "Poll is not active");
        require(block.timestamp <= polls[pollId].endTime, "Poll has ended");
        _;
    }

    constructor() {
        owner = msg.sender;
        pollIdCounter = 1;
    }

    /**
     * @dev Create a new poll
     * @param question Poll question
     * @param options Array of option strings
     * @param durationInMinutes Duration in minutes
     * @return pollId ID of created poll
     */
    function createPoll(
        string memory question,
        string[] memory options,
        uint256 durationInMinutes
    ) public onlyOwner returns (uint256) {
        require(bytes(question).length > 0, "Question cannot be empty");
        require(options.length >= 2, "Must have at least 2 options");
        require(options.length <= 10, "Maximum 10 options allowed");
        require(durationInMinutes > 0, "Duration must be greater than 0");

        uint256 pollId = pollIdCounter;
        pollIdCounter++;

        Poll storage newPoll = polls[pollId];
        newPoll.pollId = pollId;
        newPoll.question = question;
        newPoll.options = options;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = block.timestamp + (durationInMinutes * 1 minutes);
        newPoll.isActive = true;
        newPoll.exists = true;

        pollIds.push(pollId);

        emit PollCreated(pollId, question, options.length, newPoll.endTime, block.timestamp);

        return pollId;
    }

    /**
     * @dev Vote on a poll
     * @param pollId Poll ID
     * @param optionIndex Index of the option to vote for
     */
    function vote(uint256 pollId, uint256 optionIndex) 
        public 
        pollExists(pollId) 
        pollActive(pollId) 
    {
        Poll storage poll = polls[pollId];
        require(!poll.hasVoted[msg.sender], "Already voted in this poll");
        require(optionIndex < poll.options.length, "Invalid option index");

        poll.hasVoted[msg.sender] = true;
        poll.userVotes[msg.sender] = optionIndex;
        poll.voteCounts[optionIndex]++;
        poll.voters.push(msg.sender);

        emit VoteCast(pollId, msg.sender, optionIndex, block.timestamp);
    }

    /**
     * @dev End a poll manually
     * @param pollId Poll ID
     */
    function endPoll(uint256 pollId) public onlyOwner pollExists(pollId) {
        require(polls[pollId].isActive, "Poll is already ended");
        
        polls[pollId].isActive = false;

        emit PollEnded(pollId, block.timestamp);
    }

    /**
     * @dev Get poll question and options
     * @param pollId Poll ID
     * @return question Poll question
     * @return options Array of option strings
     */
    function getPollInfo(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (string memory question, string[] memory options) 
    {
        Poll storage poll = polls[pollId];
        return (poll.question, poll.options);
    }

    /**
     * @dev Get poll results
     * @param pollId Poll ID
     * @return options Array of option strings
     * @return voteCounts Array of vote counts
     */
    function getPollResults(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (string[] memory options, uint256[] memory voteCounts) 
    {
        Poll storage poll = polls[pollId];
        options = poll.options;
        voteCounts = new uint256[](poll.options.length);
        
        for (uint256 i = 0; i < poll.options.length; i++) {
            voteCounts[i] = poll.voteCounts[i];
        }
        
        return (options, voteCounts);
    }

    /**
     * @dev Get vote count for a specific option
     * @param pollId Poll ID
     * @param optionIndex Option index
     * @return Vote count
     */
    function getVoteCount(uint256 pollId, uint256 optionIndex) 
        public 
        view 
        pollExists(pollId) 
        returns (uint256) 
    {
        require(optionIndex < polls[pollId].options.length, "Invalid option index");
        return polls[pollId].voteCounts[optionIndex];
    }

    /**
     * @dev Check if user has voted in a poll
     * @param pollId Poll ID
     * @param voter Voter address
     * @return true if voted
     */
    function hasVoted(uint256 pollId, address voter) 
        public 
        view 
        pollExists(pollId) 
        returns (bool) 
    {
        return polls[pollId].hasVoted[voter];
    }

    /**
     * @dev Get user's vote in a poll
     * @param pollId Poll ID
     * @param voter Voter address
     * @return Option index voted for
     */
    function getUserVote(uint256 pollId, address voter) 
        public 
        view 
        pollExists(pollId) 
        returns (uint256) 
    {
        require(polls[pollId].hasVoted[voter], "User has not voted");
        return polls[pollId].userVotes[voter];
    }

    /**
     * @dev Get all voters for a poll
     * @param pollId Poll ID
     * @return Array of voter addresses
     */
    function getVoters(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (address[] memory) 
    {
        return polls[pollId].voters;
    }

    /**
     * @dev Get total votes in a poll
     * @param pollId Poll ID
     * @return Total vote count
     */
    function getTotalVotes(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (uint256) 
    {
        return polls[pollId].voters.length;
    }

    /**
     * @dev Get poll status
     * @param pollId Poll ID
     * @return isActive Active status
     * @return startTime Start timestamp
     * @return endTime End timestamp
     */
    function getPollStatus(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (bool isActive, uint256 startTime, uint256 endTime) 
    {
        Poll storage poll = polls[pollId];
        return (poll.isActive, poll.startTime, poll.endTime);
    }

    /**
     * @dev Get all poll IDs
     * @return Array of poll IDs
     */
    function getAllPollIds() public view returns (uint256[] memory) {
        return pollIds;
    }

    /**
     * @dev Get total number of polls
     * @return Total poll count
     */
    function getTotalPolls() public view returns (uint256) {
        return pollIds.length;
    }

    /**
     * @dev Get active polls
     * @return Array of active poll IDs
     */
    function getActivePolls() public view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < pollIds.length; i++) {
            if (polls[pollIds[i]].isActive && block.timestamp <= polls[pollIds[i]].endTime) {
                activeCount++;
            }
        }

        uint256[] memory activePolls = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < pollIds.length; i++) {
            if (polls[pollIds[i]].isActive && block.timestamp <= polls[pollIds[i]].endTime) {
                activePolls[index] = pollIds[i];
                index++;
            }
        }

        return activePolls;
    }

    /**
     * @dev Check if poll is active
     * @param pollId Poll ID
     * @return true if active
     */
    function isPollActive(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (bool) 
    {
        return polls[pollId].isActive && block.timestamp <= polls[pollId].endTime;
    }

    /**
     * @dev Get time remaining for a poll
     * @param pollId Poll ID
     * @return Seconds remaining (0 if ended)
     */
    function getTimeRemaining(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (uint256) 
    {
        if (block.timestamp >= polls[pollId].endTime) {
            return 0;
        }
        return polls[pollId].endTime - block.timestamp;
    }

    /**
     * @dev Get winning option for a poll
     * @param pollId Poll ID
     * @return winningOption Winning option string
     * @return winningVoteCount Vote count of winning option
     */
    function getWinningOption(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (string memory winningOption, uint256 winningVoteCount) 
    {
        Poll storage poll = polls[pollId];
        uint256 winningIndex = 0;
        uint256 highestVotes = poll.voteCounts[0];

        for (uint256 i = 1; i < poll.options.length; i++) {
            if (poll.voteCounts[i] > highestVotes) {
                highestVotes = poll.voteCounts[i];
                winningIndex = i;
            }
        }

        return (poll.options[winningIndex], highestVotes);
    }

    /**
     * @dev Check if caller has voted in a poll
     * @param pollId Poll ID
     * @return true if voted
     */
    function haveIVoted(uint256 pollId) 
        public 
        view 
        pollExists(pollId) 
        returns (bool) 
    {
        return polls[pollId].hasVoted[msg.sender];
    }
}
