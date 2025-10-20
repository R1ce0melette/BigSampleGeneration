// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    
    struct Poll {
        uint256 id;
        string question;
        string[] options;
        mapping(uint256 => uint256) voteCounts;
        mapping(address => bool) hasVoted;
        bool isActive;
        uint256 totalVotes;
    }
    
    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    
    event PollCreated(uint256 indexed pollId, string question, uint256 optionCount);
    event VoteCasted(uint256 indexed pollId, address indexed voter, uint256 optionIndex);
    event PollClosed(uint256 indexed pollId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createPoll(string memory _question, string[] memory _options) external onlyOwner {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(_options.length >= 2, "Must have at least 2 options");
        
        pollCount++;
        Poll storage newPoll = polls[pollCount];
        newPoll.id = pollCount;
        newPoll.question = _question;
        newPoll.isActive = true;
        newPoll.totalVotes = 0;
        
        for (uint256 i = 0; i < _options.length; i++) {
            require(bytes(_options[i]).length > 0, "Option cannot be empty");
            newPoll.options.push(_options[i]);
        }
        
        emit PollCreated(pollCount, _question, _options.length);
    }
    
    function vote(uint256 _pollId, uint256 _optionIndex) external {
        require(_pollId > 0 && _pollId <= pollCount, "Poll does not exist");
        
        Poll storage poll = polls[_pollId];
        
        require(poll.isActive, "Poll is not active");
        require(!poll.hasVoted[msg.sender], "You have already voted");
        require(_optionIndex < poll.options.length, "Invalid option index");
        
        poll.hasVoted[msg.sender] = true;
        poll.voteCounts[_optionIndex]++;
        poll.totalVotes++;
        
        emit VoteCasted(_pollId, msg.sender, _optionIndex);
    }
    
    function closePoll(uint256 _pollId) external onlyOwner {
        require(_pollId > 0 && _pollId <= pollCount, "Poll does not exist");
        
        Poll storage poll = polls[_pollId];
        require(poll.isActive, "Poll is already closed");
        
        poll.isActive = false;
        
        emit PollClosed(_pollId);
    }
    
    function getPollResults(uint256 _pollId) external view returns (
        string memory question,
        string[] memory options,
        uint256[] memory voteCounts,
        uint256 totalVotes,
        bool isActive
    ) {
        require(_pollId > 0 && _pollId <= pollCount, "Poll does not exist");
        
        Poll storage poll = polls[_pollId];
        
        uint256[] memory counts = new uint256[](poll.options.length);
        for (uint256 i = 0; i < poll.options.length; i++) {
            counts[i] = poll.voteCounts[i];
        }
        
        return (
            poll.question,
            poll.options,
            counts,
            poll.totalVotes,
            poll.isActive
        );
    }
    
    function hasUserVoted(uint256 _pollId, address _user) external view returns (bool) {
        require(_pollId > 0 && _pollId <= pollCount, "Poll does not exist");
        return polls[_pollId].hasVoted[_user];
    }
    
    function getPollQuestion(uint256 _pollId) external view returns (string memory) {
        require(_pollId > 0 && _pollId <= pollCount, "Poll does not exist");
        return polls[_pollId].question;
    }
    
    function isPollActive(uint256 _pollId) external view returns (bool) {
        require(_pollId > 0 && _pollId <= pollCount, "Poll does not exist");
        return polls[_pollId].isActive;
    }
}
