// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CommunityProposals
 * @dev A contract for managing community proposals. Members can submit proposals,
 * vote on them, and the owner can execute them if they pass.
 */
contract CommunityProposals {
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    address public owner;
    mapping(address => bool) public isMember;
    uint256 public memberCount;
    uint256 public proposalCounter;
    Proposal[] public proposals;

    event MemberAdded(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool inFavor);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true; // The owner is the first member
        memberCount = 1;
    }

    function addMember(address _newMember) public onlyOwner {
        require(_newMember != address(0), "New member cannot be the zero address.");
        require(!isMember[_newMember], "Address is already a member.");
        isMember[_newMember] = true;
        memberCount++;
        emit MemberAdded(_newMember);
    }

    function createProposal(string memory _description) public onlyMember {
        require(bytes(_description).length > 0, "Proposal description cannot be empty.");
        
        proposalCounter++;
        Proposal storage newProposal = proposals.push();
        newProposal.id = proposalCounter;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        
        emit ProposalCreated(proposalCounter, msg.sender, _description);
    }

    function vote(uint256 _proposalId, bool _inFavor) public onlyMember {
        require(_proposalId > 0 && _proposalId <= proposals.length, "Invalid proposal ID.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        if (_inFavor) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }

        emit Voted(_proposalId, msg.sender, _inFavor);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposals.length, "Invalid proposal ID.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        
        // A simple majority of "yes" votes is required to pass
        require(p.yesVotes > p.noVotes, "Proposal did not pass.");

        p.executed = true;
        // In a real application, this is where the proposed action would be triggered.
        // For this example, we just mark it as executed.
        emit ProposalExecuted(_proposalId);
    }

    function getProposal(uint256 _proposalId) public view returns (uint256, string memory, address, uint256, uint256, bool) {
        require(_proposalId > 0 && _proposalId <= proposals.length, "Invalid proposal ID.");
        Proposal storage p = proposals[_proposalId - 1];
        return (p.id, p.description, p.proposer, p.yesVotes, p.noVotes, p.executed);
    }
}
