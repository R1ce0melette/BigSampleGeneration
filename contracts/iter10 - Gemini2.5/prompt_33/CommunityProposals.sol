// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 votes;
        bool executed;
    }

    mapping(address => bool) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    Proposal[] public proposals;
    uint256 public proposalCount;
    uint256 public memberCount;

    event MemberAdded(address indexed member);
    event ProposalSubmitted(uint256 id, string title, address indexed proposer);
    event Voted(uint256 proposalId, address indexed voter);
    event ProposalExecuted(uint256 id);

    constructor() {
        members[msg.sender] = true;
        memberCount = 1;
        emit MemberAdded(msg.sender);
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    function addMember(address _newMember) public onlyMember {
        require(!members[_newMember], "Address is already a member.");
        members[_newMember] = true;
        memberCount++;
        emit MemberAdded(_newMember);
    }

    function submitProposal(string memory _title, string memory _description) public onlyMember {
        proposalCount++;
        proposals.push(Proposal(proposalCount, _title, _description, msg.sender, 0, false));
        emit ProposalSubmitted(proposalCount, _title, msg.sender);
    }

    function vote(uint256 _proposalId) public onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal.");
        
        proposals[_proposalId - 1].votes++;
        hasVoted[_proposalId][msg.sender] = true;
        emit Voted(_proposalId, msg.sender);
    }

    function executeProposal(uint256 _proposalId) public onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        require(p.votes > memberCount / 2, "Proposal does not have enough votes to be executed.");

        p.executed = true;
        // In a real scenario, this would trigger some on-chain action
        emit ProposalExecuted(_proposalId);
    }
}
