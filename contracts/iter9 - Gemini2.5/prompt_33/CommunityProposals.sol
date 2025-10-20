// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    address public owner;
    mapping(address => bool) public members;
    uint public memberCount;

    struct Proposal {
        uint id;
        string description;
        address proposer;
        uint yesVotes;
        uint noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    Proposal[] public proposals;
    uint public proposalCount;

    event MemberAdded(address indexed member);
    event ProposalSubmitted(uint id, string description, address indexed proposer);
    event Voted(uint proposalId, address indexed voter, bool inFavor);

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
        memberCount = 1;
    }

    function addMember(address _newMember) public {
        require(msg.sender == owner, "Only the owner can add new members.");
        require(!members[_newMember], "User is already a member.");
        members[_newMember] = true;
        memberCount++;
        emit MemberAdded(_newMember);
    }

    function submitProposal(string memory _description) public onlyMember {
        proposalCount++;
        proposals.push(Proposal(proposalCount, _description, msg.sender, 0, 0, false));
        emit ProposalSubmitted(proposalCount, _description, msg.sender);
    }

    function vote(uint _proposalId, bool _inFavor) public onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");
        require(!p.executed, "Proposal has already been executed.");

        p.hasVoted[msg.sender] = true;
        if (_inFavor) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }
        emit Voted(_proposalId, msg.sender, _inFavor);
    }

    function executeProposal(uint _proposalId) public {
        require(msg.sender == owner, "Only the owner can execute proposals.");
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        
        // A simple majority is required to execute.
        if (p.yesVotes > p.noVotes) {
            p.executed = true;
            // In a real-world scenario, this would trigger some on-chain action.
        }
    }
}
