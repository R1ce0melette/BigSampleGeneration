// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    string public pollQuestion;
    string[] public options;
    mapping(string => uint256) public votes;
    mapping(address => bool) public hasVoted;

    event PollCreated(string question, string[] options);
    event Voted(address indexed voter, string option);

    constructor() {
        owner = msg.sender;
    }

    function startPoll(string memory _question, string[] memory _options) public {
        require(msg.sender == owner, "Only the owner can start a poll.");
        require(bytes(pollQuestion).length == 0, "A poll is already active.");
        
        pollQuestion = _question;
        options = _options;

        emit PollCreated(_question, _options);
    }

    function vote(string memory _option) public {
        require(bytes(pollQuestion).length > 0, "No poll is currently active.");
        require(!hasVoted[msg.sender], "You have already voted.");
        
        bool validOption = false;
        for (uint i = 0; i < options.length; i++) {
            if (keccak256(bytes(options[i])) == keccak256(bytes(_option))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option.");

        hasVoted[msg.sender] = true;
        votes[_option]++;

        emit Voted(msg.sender, _option);
    }

    function getVotes(string memory _option) public view returns (uint256) {
        return votes[_option];
    }

    function endPoll() public {
        require(msg.sender == owner, "Only the owner can end the poll.");
        pollQuestion = "";
        delete options;
        // Note: This does not reset the 'votes' and 'hasVoted' mappings to allow for result checking.
        // A more complex system might archive results before clearing.
    }
}
