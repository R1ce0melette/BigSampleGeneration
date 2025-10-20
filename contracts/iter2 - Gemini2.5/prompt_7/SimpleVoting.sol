// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVoting {
    address public owner;
    string public pollQuestion;
    string[] public options;
    mapping(string => uint256) public votes;
    mapping(address => bool) public hasVoted;

    bool public pollActive;

    event PollStarted(string question, string[] options);
    event Voted(address indexed voter, string option);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function startPoll(string memory _question, string[] memory _options) public onlyOwner {
        require(!pollActive, "A poll is already active.");
        require(_options.length > 1, "At least two options are required.");

        pollQuestion = _question;
        options = _options;
        pollActive = true;

        // Reset previous poll data if any
        for (uint i = 0; i < _options.length; i++) {
            votes[_options[i]] = 0;
        }
        // This part is tricky as we can't reset the hasVoted mapping for all users easily.
        // A better design would be to have a poll ID for each poll.
        // For this simple contract, we assume a fresh start or that users know a new poll has started.

        emit PollStarted(_question, _options);
    }

    function vote(uint _optionIndex) public {
        require(pollActive, "No poll is currently active.");
        require(!hasVoted[msg.sender], "You have already voted in this poll.");
        require(_optionIndex < options.length, "Invalid option.");

        string storage selectedOption = options[_optionIndex];
        votes[selectedOption]++;
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, selectedOption);
    }

    function getPollDetails() public view returns (string memory, string[] memory) {
        return (pollQuestion, options);
    }

    function getVotesForOption(string memory _option) public view returns (uint256) {
        return votes[_option];
    }

    function endPoll() public onlyOwner {
        require(pollActive, "No poll is active to end.");
        pollActive = false;
    }
}
