// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminAccessControl {
    mapping(address => bool) public members;
    mapping(address => bool) public admins;
    uint public memberCount;
    uint public adminCount;

    enum ProposalType { AddAdmin, RemoveAdmin }
    struct Proposal {
        ProposalType pType;
        address target;
        uint yesVotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    Proposal[] public proposals;

    event MemberAdded(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint proposalId, ProposalType pType, address indexed target);
    event Voted(uint proposalId, address indexed voter);

    constructor() {
        members[msg.sender] = true;
        admins[msg.sender] = true;
        memberCount = 1;
        adminCount = 1;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    function addMember(address _newMember) public onlyAdmin {
        require(!members[_newMember], "User is already a member.");
        members[_newMember] = true;
        memberCount++;
        emit MemberAdded(_newMember);
    }

    function createProposal(ProposalType _pType, address _target) public onlyMember {
        if (_pType == ProposalType.AddAdmin) {
            require(!admins[_target], "User is already an admin.");
        } else {
            require(admins[_target], "User is not an admin.");
        }
        proposals.push(Proposal({
            pType: _pType,
            target: _target,
            yesVotes: 0,
            executed: false
        }));
        emit ProposalCreated(proposals.length - 1, _pType, _target);
    }

    function vote(uint _proposalId) public onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.yesVotes++;
        emit Voted(_proposalId, msg.sender);

        // Execute proposal if more than 50% of members have voted yes
        if (p.yesVotes * 2 > memberCount) {
            p.executed = true;
            if (p.pType == ProposalType.AddAdmin) {
                admins[p.target] = true;
                adminCount++;
                emit AdminAdded(p.target);
            } else {
                admins[p.target] = false;
                adminCount--;
                emit AdminRemoved(p.target);
            }
        }
    }
}
