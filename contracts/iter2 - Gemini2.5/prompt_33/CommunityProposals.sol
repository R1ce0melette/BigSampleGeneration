// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommunityProposals is Ownable {
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 votes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // Using an array to store proposals
    Proposal[] public proposals;
    uint256 public proposalCount;

    // For simplicity, we'll use an Ownable pattern to manage members initially.
    // A more complex system might have a separate member registration.
    mapping(address => bool) public isMember;

    event ProposalSubmitted(uint256 indexed proposalId, string title, address indexed proposer);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter);
    event MemberAdded(address indexed newMember);

    constructor() Ownable(msg.sender) {
        // The deployer is the first member
        isMember[msg.sender] = true;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    function addMember(address _newMember) public onlyOwner {
        require(_newMember != address(0), "New member address cannot be zero.");
        require(!isMember[_newMember], "Address is already a member.");
        isMember[_newMember] = true;
        emit MemberAdded(_newMember);
    }

    function submitProposal(string memory _title, string memory _description) public onlyMember {
        require(bytes(_title).length > 0, "Title cannot be empty.");
        
        proposalCount++;
        proposals.push(Proposal({
            id: proposalCount,
            title: _title,
            description: _description,
            proposer: msg.sender,
            votes: 0,
            executed: false
        }));

        emit ProposalSubmitted(proposalCount, _title, msg.sender);
    }

    function vote(uint256 _proposalId) public onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit VotedOnProposal(_proposalId, msg.sender);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        
        // Example execution logic: mark as executed. A real contract would do more.
        // For example, if a proposal gets a certain number of votes, it could trigger a state change.
        p.executed = true;
    }

    function getProposal(uint256 _proposalId) public view returns (uint256, string memory, string memory, address, uint256, bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        return (p.id, p.title, p.description, p.proposer, p.votes, p.executed);
    }
}
