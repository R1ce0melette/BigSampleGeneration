// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    string public pollQuestion;
    string[] public options;
    mapping(string => uint256) public votes;
    mapping(address => bool) public hasVoted;

    enum State { Created, Started, Ended }
    State public currentState;

    event PollStarted(string question, string[] options);
    event Voted(address indexed voter, string option);
    event PollEnded();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier inState(State _state) {
        require(currentState == _state, "Invalid state for this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        currentState = State.Created;
    }

    function startPoll(string memory _question, string[] memory _options) public onlyOwner inState(State.Created) {
        require(_options.length > 1, "At least two options are required.");
        pollQuestion = _question;
        options = _options;
        currentState = State.Started;
        emit PollStarted(_question, _options);
    }

    function vote(uint _optionIndex) public inState(State.Started) {
        require(!hasVoted[msg.sender], "You have already voted.");
        require(_optionIndex < options.length, "Invalid option.");

        hasVoted[msg.sender] = true;
        string storage selectedOption = options[_optionIndex];
        votes[selectedOption]++;
        emit Voted(msg.sender, selectedOption);
    }

    function endPoll() public onlyOwner inState(State.Started) {
        currentState = State.Ended;
        emit PollEnded();
    }

    function getVoteCount(string memory _option) public view returns (uint256) {
        return votes[_option];
    }
}
