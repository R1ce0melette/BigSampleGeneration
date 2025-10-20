// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CommunityProposals
 * @dev A contract for managing community proposals and voting.
 */
contract CommunityProposals {

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 votes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    address public owner;
    mapping(address => bool) public isMember;
    uint256 public memberCount;
    uint256 public proposalCount;
    Proposal[] public proposals;

    event MemberAdded(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter);

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true;
        memberCount = 1;
    }

    /**
     * @dev Adds a new member to the community.
     */
    function addMember(address _newMember) public {
        require(msg.sender == owner, "Only the owner can add members.");
        require(!isMember[_newMember], "Address is already a member.");
        isMember[_newMember] = true;
        memberCount++;
        emit MemberAdded(_newMember);
    }

    /**
     * @dev Creates a new proposal.
     */
    function createProposal(string memory _description) public onlyMember {
        uint256 proposalId = proposalCount;
        proposals.push(Proposal({
            id: proposalId,
            description: _description,
            proposer: msg.sender,
            votes: 0,
            executed: false
        }));
        proposalCount++;
        emit ProposalCreated(proposalId, _description, msg.sender);
    }

    /**
     * @dev Allows a member to vote on a proposal.
     */
    function vote(uint256 _proposalId) public onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");
        
        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_proposalId, msg.sender);
    }
}
