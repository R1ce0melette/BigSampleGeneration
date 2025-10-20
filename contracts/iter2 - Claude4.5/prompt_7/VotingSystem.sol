// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    
    struct Poll {
        uint256 pollId;
        string question;
        string[] options;
        mapping(uint256 => uint256) votes;
        mapping(address => bool) hasVoted;
        bool isActive;
        uint256 totalVotes;
    }
    
    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    
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
    
    function createPoll(string memory _question, string[] memory _options) external onlyOwner {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(_options.length >= 2, "Must have at least 2 options");
        
        pollCount++;
        
        Poll storage newPoll = polls[pollCount];
        newPoll.pollId = pollCount;
        newPoll.question = _question;
        newPoll.isActive = true;
        newPoll.totalVotes = 0;
        
        for (uint256 i = 0; i < _options.length; i++) {
            require(bytes(_options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(_options[i]);
        }
        
        emit PollCreated(pollCount, _question, _options.length);
    }
    
    function vote(uint256 _pollId, uint256 _optionIndex) external {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[_pollId];
        
        require(poll.isActive, "Poll is not active");
        require(!poll.hasVoted[msg.sender], "Already voted in this poll");
        require(_optionIndex < poll.options.length, "Invalid option index");
        
        poll.hasVoted[msg.sender] = true;
        poll.votes[_optionIndex]++;
        poll.totalVotes++;
        
        emit VoteCast(_pollId, msg.sender, _optionIndex);
    }
    
    function endPoll(uint256 _pollId) external onlyOwner {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[_pollId];
        
        require(poll.isActive, "Poll is already ended");
        
        poll.isActive = false;
        
        emit PollEnded(_pollId);
    }
    
    function getPollInfo(uint256 _pollId) external view returns (
        string memory question,
        string[] memory options,
        bool isActive,
        uint256 totalVotes
    ) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[_pollId];
        
        return (
            poll.question,
            poll.options,
            poll.isActive,
            poll.totalVotes
        );
    }
    
    function getVotesForOption(uint256 _pollId, uint256 _optionIndex) external view returns (uint256) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[_pollId];
        require(_optionIndex < poll.options.length, "Invalid option index");
        
        return poll.votes[_optionIndex];
    }
    
    function getAllVotes(uint256 _pollId) external view returns (uint256[] memory) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        Poll storage poll = polls[_pollId];
        
        uint256[] memory voteCounts = new uint256[](poll.options.length);
        for (uint256 i = 0; i < poll.options.length; i++) {
            voteCounts[i] = poll.votes[i];
        }
        
        return voteCounts;
    }
    
    function hasUserVoted(uint256 _pollId, address _user) external view returns (bool) {
        require(_pollId > 0 && _pollId <= pollCount, "Invalid poll ID");
        return polls[_pollId].hasVoted[_user];
    }
}
