// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    address public owner;

    struct Proposal {
        string description;
        address proposer;
        uint256 voteCount;
        bool executed;
        mapping(address => bool) voters;
    }

    mapping(address => bool) public isMember;
    Proposal[] public proposals;
    uint256 public memberCount;

    event MemberAdded(address indexed newMember);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        // The contract creator is the first member
        isMember[msg.sender] = true;
        memberCount = 1;
    }

    function addMember(address _newMember) public onlyOwner {
        require(!isMember[_newMember], "Address is already a member.");
        isMember[_newMember] = true;
        memberCount++;
        emit MemberAdded(_newMember);
    }

    function createProposal(string calldata _description) public onlyMember {
        uint256 proposalId = proposals.length;
        Proposal storage newProposal = proposals.push();
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    function vote(uint256 _proposalId) public onlyMember {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        require(!p.voters[msg.sender], "You have already voted on this proposal.");
        require(!p.executed, "This proposal has already been executed.");

        p.voters[msg.sender] = true;
        p.voteCount++;
        emit Voted(_proposalId, msg.sender);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "This proposal has already been executed.");
        
        // For a proposal to pass, it needs more than 50% of the members' votes.
        uint256 requiredVotes = memberCount / 2;
        require(p.voteCount > requiredVotes, "Proposal does not have enough votes to be executed.");

        p.executed = true;
        // In a real-world scenario, this is where the proposal's action would be triggered.
        // For this example, we just mark it as executed.
        emit ProposalExecuted(_proposalId);
    }

    function getProposal(uint256 _proposalId) public view returns (string memory, address, uint256, bool) {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        return (p.description, p.proposer, p.voteCount, p.executed);
    }
}
