// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    string[] public options;
    mapping(string => uint256) public votes;
    mapping(address => bool) public hasVoted;
    bool public pollActive;

    event PollStarted(string[] options);
    event Voted(address indexed voter, string option);
    event PollEnded();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function startPoll(string[] memory _options) external onlyOwner {
        require(!pollActive, "Poll already active");
        require(_options.length > 1, "At least 2 options");
        delete options;
        for (uint i = 0; i < _options.length; i++) {
            options.push(_options[i]);
            votes[_options[i]] = 0;
        }
        pollActive = true;
        emit PollStarted(_options);
    }

    function vote(string calldata option) external {
        require(pollActive, "No active poll");
        require(!hasVoted[msg.sender], "Already voted");
        bool valid = false;
        for (uint i = 0; i < options.length; i++) {
            if (keccak256(bytes(options[i])) == keccak256(bytes(option))) {
                valid = true;
                break;
            }
        }
        require(valid, "Invalid option");
        votes[option] += 1;
        hasVoted[msg.sender] = true;
        emit Voted(msg.sender, option);
    }

    function endPoll() external onlyOwner {
        require(pollActive, "No active poll");
        pollActive = false;
        emit PollEnded();
    }

    function getOptions() external view returns (string[] memory) {
        return options;
    }

    function getVotes(string calldata option) external view returns (uint256) {
        return votes[option];
    }
}
