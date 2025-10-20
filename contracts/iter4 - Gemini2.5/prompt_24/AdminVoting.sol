// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminVoting {
    mapping(address => bool) public isAdmin;
    uint256 public adminCount;
    uint256 public requiredVotes;

    enum ProposalType { Add, Remove }
    struct Proposal {
        ProposalType pType;
        address target;
        uint256 votes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    Proposal[] public proposals;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);
    event ProposalCreated(uint256 indexed proposalId, ProposalType pType, address indexed target);
    event Voted(uint256 indexed proposalId, address indexed voter);

    constructor(address[] memory _initialAdmins) {
        require(_initialAdmins.length > 0, "Must have at least one initial admin.");
        for (uint i = 0; i < _initialAdmins.length; i++) {
            isAdmin[_initialAdmins[i]] = true;
        }
        adminCount = _initialAdmins.length;
        updateRequiredVotes();
    }

    function updateRequiredVotes() private {
        requiredVotes = (adminCount / 2) + 1;
    }

    function createProposal(ProposalType _pType, address _target) public {
        require(isAdmin[msg.sender], "Only admins can create proposals.");
        if (_pType == ProposalType.Add) {
            require(!isAdmin[_target], "Target is already an admin.");
        } else { // Remove
            require(isAdmin[_target], "Target is not an admin.");
        }

        proposals.push();
        Proposal storage newProposal = proposals[proposals.length - 1];
        newProposal.pType = _pType;
        newProposal.target = _target;
        newProposal.executed = false;

        emit ProposalCreated(proposals.length - 1, _pType, _target);
    }

    function vote(uint256 _proposalId) public {
        require(isAdmin[msg.sender], "Only admins can vote.");
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
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
        Proposal storage p = proposals[_proposalId];
        p.executed = true;

        if (p.pType == ProposalType.Add) {
            isAdmin[p.target] = true;
            adminCount++;
            emit AdminAdded(p.target);
        } else { // Remove
            isAdmin[p.target] = false;
            adminCount--;
            emit AdminRemoved(p.target);
        }
        updateRequiredVotes();
    }

    function getProposal(uint256 _proposalId) public view returns (ProposalType, address, uint256, bool) {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        return (p.pType, p.target, p.votes, p.executed);
    }
    
    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }
}
