// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVoting {
    address public owner;
    string[] public options;
    mapping(uint256 => uint256) public votes;
    mapping(address => bool) public hasVoted;
    bool public pollActive;

    event PollStarted(string[] options);
    event Voted(address indexed voter, uint256 option);
    event PollEnded();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function startPoll(string[] calldata _options) external onlyOwner {
        require(!pollActive, "Poll already active");
        require(_options.length > 1, "Need at least 2 options");
        delete options;
        for (uint256 i = 0; i < _options.length; i++) {
            options.push(_options[i]);
            votes[i] = 0;
        }
        pollActive = true;
        emit PollStarted(_options);
    }

    function vote(uint256 option) external {
        require(pollActive, "No active poll");
        require(!hasVoted[msg.sender], "Already voted");
        require(option < options.length, "Invalid option");
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
}
