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

        emit PollStarted(_question, _options);
    }

    function vote(string memory _option) public {
        require(pollActive, "No poll is currently active.");
        require(!hasVoted[msg.sender], "You have already voted.");
        
        bool validOption = false;
        for (uint i = 0; i < options.length; i++) {
            if (keccak256(bytes(options[i])) == keccak256(bytes(_option))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option.");

        votes[_option]++;
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, _option);
    }

    function endPoll() public onlyOwner {
        require(pollActive, "No poll is currently active.");
        pollActive = false;
    }

    function getVoteCount(string memory _option) public view returns (uint256) {
        return votes[_option];
    }
}
