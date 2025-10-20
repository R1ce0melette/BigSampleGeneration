// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVoting {
    address public owner;
    string[] public options;
    mapping(uint256 => uint256) public votes;
    mapping(address => bool) public hasVoted;
    bool public pollActive;

    constructor() {
        owner = msg.sender;
    }

    function startPoll(string[] calldata _options) external {
        require(msg.sender == owner, "Only owner");
        require(!pollActive, "Poll already active");
        delete options;
        for (uint256 i = 0; i < _options.length; i++) {
            options.push(_options[i]);
        }
        pollActive = true;
        for (uint256 i = 0; i < options.length; i++) {
            votes[i] = 0;
        }
        // Reset votes and hasVoted
        // Not resetting hasVoted for simplicity; in production, consider resetting or using pollId
    }

    function vote(uint256 option) external {
        require(pollActive, "No active poll");
        require(!hasVoted[msg.sender], "Already voted");
        require(option < options.length, "Invalid option");
        hasVoted[msg.sender] = true;
        votes[option] += 1;
    }

    function endPoll() external {
        require(msg.sender == owner, "Only owner");
        require(pollActive, "No active poll");
        pollActive = false;
    }

    function getOptions() external view returns (string[] memory) {
        return options;
    }
}
