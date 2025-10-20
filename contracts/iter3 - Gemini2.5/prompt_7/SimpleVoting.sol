// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleVoting
 * @dev A contract for a simple voting system with predefined options.
 * The owner can start a poll, and users can cast their votes.
 */
contract SimpleVoting {
    address public owner;
    string public pollQuestion;
    string[] public options;
    mapping(uint256 => uint256) public votesPerOption;
    mapping(address => bool) public hasVoted;

    bool public pollActive = false;

    /**
     * @dev Emitted when a new poll is started.
     * @param question The question of the poll.
     * @param pollOptions The list of options for the poll.
     */
    event PollStarted(string question, string[] pollOptions);

    /**
     * @dev Emitted when a user casts a vote.
     * @param voter The address of the voter.
     * @param optionIndex The index of the option voted for.
     */
    event Voted(address indexed voter, uint256 optionIndex);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the contract owner upon deployment.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Starts a new poll with a question and a list of options.
     * Only the owner can start a poll, and only when no other poll is active.
     * @param _question The question for the poll.
     * @param _options The list of options for voting.
     */
    function startPoll(string memory _question, string[] memory _options) public onlyOwner {
        require(!pollActive, "A poll is already active.");
        require(bytes(_question).length > 0, "Poll question cannot be empty.");
        require(_options.length > 1, "There must be at least two options.");

        pollQuestion = _question;
        options = _options;
        pollActive = true;

        // Reset votes for the new poll
        for (uint256 i = 0; i < _options.length; i++) {
            votesPerOption[i] = 0;
        }

        emit PollStarted(_question, _options);
    }

    /**
     * @dev Allows a user to cast a vote for a specific option.
     * A user can only vote once per poll.
     * @param optionIndex The index of the option to vote for.
     */
    function vote(uint256 optionIndex) public {
        require(pollActive, "No poll is currently active.");
        require(!hasVoted[msg.sender], "You have already voted in this poll.");
        require(optionIndex < options.length, "Invalid option index.");

        hasVoted[msg.sender] = true;
        votesPerOption[optionIndex]++;

        emit Voted(msg.sender, optionIndex);
    }

    /**
     * @dev Ends the current poll. Only the owner can end a poll.
     * This allows for starting a new poll.
     */
    function endPoll() public onlyOwner {
        require(pollActive, "No poll is currently active.");
        pollActive = false;
        // Note: This does not automatically reset voter participation (`hasVoted`).
        // A new `startPoll` call will be needed to clear state for a new poll.
    }

    /**
     * @dev Retrieves the details of the current poll.
     * @return The poll question and the list of options.
     */
    function getPollDetails() public view returns (string memory, string[] memory) {
        return (pollQuestion, options);
    }

    /**
     * @dev Retrieves the number of votes for a specific option.
     * @param optionIndex The index of the option.
     * @return The total number of votes for the option.
     */
    function getVotesForOption(uint256 optionIndex) public view returns (uint256) {
        require(optionIndex < options.length, "Invalid option index.");
        return votesPerOption[optionIndex];
    }
}
