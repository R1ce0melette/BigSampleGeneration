// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VotingBasedAccessControl
 * @dev A contract for managing admin roles through a voting process.
 */
contract VotingBasedAccessControl {

    enum ProposalType { AddAdmin, RemoveAdmin }

    struct Proposal {
        uint256 id;
        ProposalType pType;
        address target;
        uint256 votes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    address public owner;
    mapping(address => bool) public isAdmin;
    uint256 public adminCount;
    uint256 public proposalCount;
    Proposal[] public proposals;

    event ProposalCreated(uint256 indexed proposalId, ProposalType pType, address indexed target);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        adminCount = 1;
    }

    /**
     * @dev Creates a new proposal to add or remove an admin.
     */
    function createProposal(ProposalType _pType, address _target) public onlyAdmin {
        require(_target != address(0), "Target address cannot be zero.");
        if (_pType == ProposalType.AddAdmin) {
            require(!isAdmin[_target], "Target is already an admin.");
        } else {
            require(isAdmin[_target], "Target is not an admin.");
        }

        uint256 proposalId = proposalCount;
        proposals.push(Proposal({
            id: proposalId,
            pType: _pType,
            target: _target,
            votes: 0,
            executed: false
        }));
        proposalCount++;
        emit ProposalCreated(proposalId, _pType, _target);
    }

    /**
     * @dev Allows an admin to vote on a proposal.
     */
    function vote(uint256 _proposalId) public onlyAdmin {
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_proposalId, msg.sender);
    }

    /**
     * @dev Executes a proposal if it has received enough votes.
     */
    function executeProposal(uint256 _proposalId) public onlyAdmin {
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal has already been executed.");
        require(p.votes > adminCount / 2, "Proposal does not have enough votes.");

        p.executed = true;
        if (p.pType == ProposalType.AddAdmin) {
            isAdmin[p.target] = true;
            adminCount++;
        } else {
            isAdmin[p.target] = false;
            adminCount--;
        }
        emit ProposalExecuted(_proposalId);
    }
}
