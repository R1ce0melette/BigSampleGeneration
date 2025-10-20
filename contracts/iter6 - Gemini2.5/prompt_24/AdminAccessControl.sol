// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminAccessControl {
    mapping(address => bool) public members;
    mapping(address => bool) public admins;
    uint256 public memberCount;
    uint256 public adminThreshold; // Number of votes required to add/remove an admin

    enum ProposalType { AddAdmin, RemoveAdmin }
    struct Proposal {
        ProposalType pType;
        address target;
        uint256 votes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    Proposal[] public proposals;

    event MemberAdded(address indexed newMember);
    event ProposalCreated(uint256 indexed proposalId, ProposalType pType, address indexed target);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address[] memory _initialMembers, uint256 _adminThreshold) {
        for (uint i = 0; i < _initialMembers.length; i++) {
            members[_initialMembers[i]] = true;
            emit MemberAdded(_initialMembers[i]);
        }
        memberCount = _initialMembers.length;
        adminThreshold = _adminThreshold;
        admins[msg.sender] = true; // The deployer is the first admin
    }

    function createProposal(ProposalType _pType, address _target) public {
        require(members[msg.sender], "Only members can create proposals.");
        proposals.push(Proposal({
            pType: _pType,
            target: _target,
            votes: 0,
            executed: false
        }));
        emit ProposalCreated(proposals.length - 1, _pType, _target);
    }

    function vote(uint256 _proposalId) public {
        require(members[msg.sender], "Only members can vote.");
        Proposal storage p = proposals[_proposalId];
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");
        
        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_proposalId, msg.sender);
    }

    function executeProposal(uint256 _proposalId) public {
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal already executed.");
        require(p.votes >= adminThreshold, "Proposal has not met the vote threshold.");

        p.executed = true;
        if (p.pType == ProposalType.AddAdmin) {
            admins[p.target] = true;
        } else if (p.pType == ProposalType.RemoveAdmin) {
            admins[p.target] = false;
        }
        emit ProposalExecuted(_proposalId);
    }

    function isAdmin(address _user) public view returns (bool) {
        return admins[_user];
    }
}
