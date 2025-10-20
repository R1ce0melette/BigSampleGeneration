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
        uint256 totalVotes;
    }

    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;

    event PollCreated(uint256 indexed pollId, string question, uint256 optionCount);
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 optionIndex);
    event PollEnded(uint256 indexed pollId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPoll(string memory question, string[] memory options) external onlyOwner {
        require(bytes(question).length > 0, "Question cannot be empty");
        require(options.length >= 2, "Must have at least 2 options");

        pollCount++;
        Poll storage newPoll = polls[pollCount];
        newPoll.id = pollCount;
        newPoll.question = question;
        newPoll.active = true;
        newPoll.totalVotes = 0;

        for (uint256 i = 0; i < options.length; i++) {
            require(bytes(options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(options[i]);
        }

        emit PollCreated(pollCount, question, options.length);
    }

    function vote(uint256 pollId, uint256 optionIndex) external {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        Poll storage poll = polls[pollId];
        require(poll.active, "Poll is not active");
        require(!poll.hasVoted[msg.sender], "Already voted in this poll");
        require(optionIndex < poll.options.length, "Invalid option index");

        poll.hasVoted[msg.sender] = true;
        poll.votes[optionIndex]++;
        poll.totalVotes++;

        emit VoteCast(pollId, msg.sender, optionIndex);
    }

    function endPoll(uint256 pollId) external onlyOwner {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        Poll storage poll = polls[pollId];
        require(poll.active, "Poll is already ended");

        poll.active = false;

        emit PollEnded(pollId);
    }

    function getPollQuestion(uint256 pollId) external view returns (string memory) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        return polls[pollId].question;
    }

    function getPollOptions(uint256 pollId) external view returns (string[] memory) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        return polls[pollId].options;
    }

    function getVoteCount(uint256 pollId, uint256 optionIndex) external view returns (uint256) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        require(optionIndex < polls[pollId].options.length, "Invalid option index");
        return polls[pollId].votes[optionIndex];
    }

    function hasVoted(uint256 pollId, address voter) external view returns (bool) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        return polls[pollId].hasVoted[voter];
    }

    function isPollActive(uint256 pollId) external view returns (bool) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        return polls[pollId].active;
    }

    function getTotalVotes(uint256 pollId) external view returns (uint256) {
        require(pollId > 0 && pollId <= pollCount, "Poll does not exist");
        return polls[pollId].totalVotes;
    }
}
