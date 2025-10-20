// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    address[] public admins;
    address[] public members;

    struct Proposal {
        address candidate;
        bool add;
        uint256 votes;
        bool executed;
        mapping(address => bool) voted;
    }

    Proposal[] public proposals;
    uint256 public proposalCount;

    event MemberAdded(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint256 indexed id, address candidate, bool add);
    event Voted(uint256 indexed id, address voter);
    event ProposalExecuted(uint256 indexed id, address candidate, bool add);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    constructor(address[] memory initialAdmins, address[] memory initialMembers) {
        require(initialAdmins.length > 0, "At least one admin");
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            isAdmin[initialAdmins[i]] = true;
            admins.push(initialAdmins[i]);
        }
        for (uint256 i = 0; i < initialMembers.length; i++) {
            isMember[initialMembers[i]] = true;
            members.push(initialMembers[i]);
            emit MemberAdded(initialMembers[i]);
        }
    }

    function propose(address candidate, bool add) external onlyAdmin {
        proposals.push();
        Proposal storage p = proposals[proposals.length - 1];
        p.candidate = candidate;
        p.add = add;
        p.votes = 0;
        p.executed = false;
        proposalCount++;
        emit ProposalCreated(proposals.length - 1, candidate, add);
    }

    function vote(uint256 proposalId) external onlyAdmin {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage p = proposals[proposalId];
        require(!p.voted[msg.sender], "Already voted");
        require(!p.executed, "Already executed");
        p.voted[msg.sender] = true;
        p.votes++;
        emit Voted(proposalId, msg.sender);
        if (p.votes > admins.length / 2) {
            executeProposal(proposalId);
        }
    }

    function executeProposal(uint256 proposalId) internal {
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");
        p.executed = true;
        if (p.add) {
            isAdmin[p.candidate] = true;
            admins.push(p.candidate);
            emit AdminAdded(p.candidate);
        } else {
            isAdmin[p.candidate] = false;
            emit AdminRemoved(p.candidate);
        }
        emit ProposalExecuted(proposalId, p.candidate, p.add);
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }
}
