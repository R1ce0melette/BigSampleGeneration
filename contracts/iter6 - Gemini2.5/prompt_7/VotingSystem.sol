// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    string public pollQuestion;
    string[] public options;
    mapping(string => uint256) public votes;
    mapping(address => bool) public hasVoted;
    bool public pollActive;

    event PollStarted(string question, string[] options);
    event Voted(address indexed voter, string option);

    constructor() {
        owner = msg.sender;
    }

    function startPoll(string memory _question, string[] memory _options) public {
        require(msg.sender == owner, "Only the owner can start a poll.");
        require(!pollActive, "A poll is already active.");
        
        pollQuestion = _question;
        options = _options;
        pollActive = true;

        emit PollStarted(_question, _options);
    }

    function vote(uint256 _optionIndex) public {
        require(pollActive, "No poll is currently active.");
        require(!hasVoted[msg.sender], "You have already voted.");
        require(_optionIndex < options.length, "Invalid option.");

        hasVoted[msg.sender] = true;
        string storage selectedOption = options[_optionIndex];
        votes[selectedOption]++;

        emit Voted(msg.sender, selectedOption);
    }

    function getVotes(string memory _option) public view returns (uint256) {
        return votes[_option];
    }

    function endPoll() public {
        require(msg.sender == owner, "Only the owner can end the poll.");
        pollActive = false;
    }
}
