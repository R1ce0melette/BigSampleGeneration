// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    address public owner;
    mapping(address => bool) public isMember;
    uint256 public memberCount;

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 votes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    Proposal[] public proposals;
    uint256 public proposalCounter;
    uint256 public requiredVotes;

    event MemberAdded(address indexed newMember);
    event ProposalCreated(uint256 indexed id, string description, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed id);

    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true; // The creator is the first member
        memberCount = 1;
        updateRequiredVotes();
    }

    function addMember(address _newMember) public {
        require(msg.sender == owner, "Only the owner can add new members.");
        require(!isMember[_newMember], "Address is already a member.");
        isMember[_newMember] = true;
        memberCount++;
        updateRequiredVotes();
        emit MemberAdded(_newMember);
    }

    function updateRequiredVotes() private {
        requiredVotes = (memberCount / 2) + 1;
    }

    function createProposal(string memory _description) public {
        require(isMember[msg.sender], "Only members can create proposals.");
        proposalCounter++;
        proposals.push();
        Proposal storage newProposal = proposals[proposals.length - 1];
        newProposal.id = proposalCounter;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalCounter, _description, msg.sender);
    }

    function vote(uint256 _proposalId) public {
        require(isMember[msg.sender], "Only members can vote.");
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_proposalId, msg.sender);

        if (p.votes >= requiredVotes) {
            executeProposal(_proposalId);
        }
    }

    function executeProposal(uint256 _proposalId) private {
        Proposal storage p = proposals[_proposalId - 1];
        p.executed = true;
        // In a real scenario, this would trigger some on-chain action.
        // For this example, we just mark it as executed.
        emit ProposalExecuted(_proposalId);
    }

    function getProposal(uint256 _proposalId) public view returns (uint256, string memory, address, uint256, bool) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        return (p.id, p.description, p.proposer, p.votes, p.executed);
    }

    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }
}
