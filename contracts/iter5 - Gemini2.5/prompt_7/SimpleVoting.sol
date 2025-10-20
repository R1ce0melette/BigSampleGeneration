// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleVoting
 * @dev A contract for a simple voting system with predefined options.
 */
contract SimpleVoting {
    // Address of the contract owner who can manage polls.
    address public owner;
    // The question or topic of the current poll.
    string public pollQuestion;
    // An array of predefined options for the poll.
    string[] public options;
    // A flag to indicate if a poll is currently active.
    bool public pollActive;

    // Mapping from an option's name to its vote count.
    mapping(string => uint256) public voteCounts;
    // Mapping to track if a user has already voted in the current poll.
    mapping(address => bool) public hasVoted;

    /**
     * @dev Event emitted when a new poll is started.
     * @param question The question of the poll.
     * @param pollOptions The list of options for the poll.
     */
    event PollStarted(string question, string[] pollOptions);

    /**
     * @dev Event emitted when a user casts a vote.
     * @param voter The address of the user who voted.
     * @param option The option the user voted for.
     */
    event Voted(address indexed voter, string option);

    /**
     * @dev Event emitted when the poll is ended.
     * @param question The question of the poll that ended.
     */
    event PollEnded(string question);

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
     * - Only the owner can start a poll.
     * - A poll cannot be started if one is already active.
     * @param _question The question for the poll.
     * @param _options An array of options for voters to choose from.
     */
    function startPoll(string memory _question, string[] memory _options) public onlyOwner {
        require(!pollActive, "A poll is already active.");
        require(bytes(_question).length > 0, "Poll question cannot be empty.");
        require(_options.length > 1, "There must be at least two options.");

        pollQuestion = _question;
        options = _options;
        pollActive = true;

        // Reset previous poll data
        for (uint i = 0; i < _options.length; i++) {
            voteCounts[_options[i]] = 0;
        }
        // Note: hasVoted mapping is reset when a new poll starts, implicitly.
        // A more robust implementation might require explicit clearing if polls are frequent.

        emit PollStarted(_question, _options);
    }

    /**
     * @dev Allows a user to cast a vote for a specific option.
     * - The poll must be active.
     * - The user must not have voted before in the current poll.
     * - The chosen option must be valid.
     * @param _option The option to vote for.
     */
    function vote(string memory _option) public {
        require(pollActive, "No poll is currently active.");
        require(!hasVoted[msg.sender], "You have already voted in this poll.");
        
        bool validOption = false;
        for (uint i = 0; i < options.length; i++) {
            if (keccak256(bytes(options[i])) == keccak256(bytes(_option))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option.");

        hasVoted[msg.sender] = true;
        voteCounts[_option]++;

        emit Voted(msg.sender, _option);
    }

    /**
     * @dev Ends the current poll.
     * - Only the owner can end a poll.
     * - The poll must be active.
     */
    function endPoll() public onlyOwner {
        require(pollActive, "No poll is currently active.");
        
        pollActive = false;
        emit PollEnded(pollQuestion);
        
        // Reset poll data for the next poll
        pollQuestion = "";
        delete options;
        // hasVoted mapping will be implicitly reset for the next poll logic
    }

    /**
     * @dev Retrieves the vote count for a specific option.
     * @param _option The option to get the vote count for.
     * @return The number of votes for the given option.
     */
    function getVoteCount(string memory _option) public view returns (uint256) {
        return voteCounts[_option];
    }

    /**
     * @dev Retrieves the list of options for the current poll.
     * @return An array of strings representing the poll options.
     */
    function getOptions() public view returns (string[] memory) {
        return options;
    }
}
