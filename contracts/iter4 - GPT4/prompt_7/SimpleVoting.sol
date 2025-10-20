// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVoting {
    address public owner;
    string[] public options;
    mapping(uint256 => uint256) public votes;
    mapping(address => bool) public hasVoted;
    bool public pollActive;

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
        options = _options;
        pollActive = true;
        for (uint256 i = 0; i < options.length; i++) {
            votes[i] = 0;
        }
        // Reset votes
        for (uint256 i = 0; i < options.length; i++) {
            votes[i] = 0;
        }
    }

    function vote(uint256 option) external {
        require(pollActive, "No active poll");
        require(!hasVoted[msg.sender], "Already voted");
        require(option < options.length, "Invalid option");
        hasVoted[msg.sender] = true;
        votes[option] += 1;
    }

    function endPoll() external onlyOwner {
        require(pollActive, "No active poll");
        pollActive = false;
    }

    function getOptions() external view returns (string[] memory) {
        return options;
    }
}
