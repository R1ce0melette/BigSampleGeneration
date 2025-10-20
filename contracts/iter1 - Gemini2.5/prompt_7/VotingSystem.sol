// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    string public pollQuestion;
    string[] public options;
    mapping(uint256 => uint256) public votes;
    mapping(address => bool) public hasVoted;

    event PollStarted(string question, string[] options);
    event Voted(address voter, uint256 option);

    constructor() {
        owner = msg.sender;
    }

    function startPoll(string memory _question, string[] memory _options) public {
        require(msg.sender == owner, "Only the owner can start a poll");
        require(bytes(pollQuestion).length == 0, "A poll is already active");
        require(_options.length > 1, "At least two options are required");

        pollQuestion = _question;
        options = _options;

        emit PollStarted(_question, _options);
    }

    function vote(uint256 _option) public {
        require(bytes(pollQuestion).length > 0, "No poll is active");
        require(!hasVoted[msg.sender], "You have already voted");
        require(_option < options.length, "Invalid option");

        hasVoted[msg.sender] = true;
        votes[_option]++;

        emit Voted(msg.sender, _option);
    }

    function getPollDetails() public view returns (string memory, string[] memory) {
        return (pollQuestion, options);
    }

    function getVoteCount(uint256 _option) public view returns (uint256) {
        require(_option < options.length, "Invalid option");
        return votes[_option];
    }
}
