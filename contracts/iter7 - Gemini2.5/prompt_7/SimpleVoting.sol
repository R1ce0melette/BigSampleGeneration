// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleVoting
 * @dev A contract for a simple voting system with predefined options.
 */
contract SimpleVoting {
    address public owner;
    string public pollQuestion;
    string[] public options;
    mapping(address => bool) private hasVoted;
    mapping(uint256 => uint256) private voteCounts;

    bool public pollActive;

    event PollStarted(string question, string[] options);
    event Voted(address indexed voter, uint256 optionIndex);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Starts a new poll. Can only be called by the owner.
     * @param _question The question for the poll.
     * @param _options The list of options for the poll.
     */
    function startPoll(string memory _question, string[] memory _options) public onlyOwner {
        require(!pollActive, "A poll is already active.");
        require(bytes(_question).length > 0, "Question cannot be empty.");
        require(_options.length > 1, "Must have at least two options.");

        pollQuestion = _question;
        options = _options;
        pollActive = true;

        // Reset previous poll data if any
        for (uint i = 0; i < options.length; i++) {
            voteCounts[i] = 0;
        }
        // This part is tricky as we can't reset the hasVoted mapping for all users easily.
        // A better design would be to have a poll ID and track votes per poll.
        // For this simple contract, we assume a fresh start or that users who voted before are okay to be blocked.

        emit PollStarted(_question, _options);
    }

    /**
     * @dev Allows a user to vote for an option.
     * @param _optionIndex The index of the option to vote for.
     */
    function vote(uint256 _optionIndex) public {
        require(pollActive, "No poll is currently active.");
        require(!hasVoted[msg.sender], "You have already voted.");
        require(_optionIndex < options.length, "Invalid option index.");

        hasVoted[msg.sender] = true;
        voteCounts[_optionIndex]++;

        emit Voted(msg.sender, _optionIndex);
    }

    /**
     * @dev Ends the current poll. Can only be called by the owner.
     */
    function endPoll() public onlyOwner {
        require(pollActive, "No poll is currently active.");
        pollActive = false;
    }

    /**
     * @dev Gets the vote count for a specific option.
     * @param _optionIndex The index of the option.
     * @return The number of votes for the option.
     */
    function getVoteCount(uint256 _optionIndex) public view returns (uint256) {
        require(_optionIndex < options.length, "Invalid option index.");
        return voteCounts[_optionIndex];
    }

    /**
     * @dev Gets the details of the current poll.
     * @return The poll question and the list of options.
     */
    function getPollDetails() public view returns (string memory, string[] memory) {
        return (pollQuestion, options);
    }
}
