// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminVoting {
    mapping(address => bool) public isAdmin;
    address[] public admins;
    uint public adminCount;

    enum ProposalType { AddAdmin, RemoveAdmin }
    struct Proposal {
        ProposalType pType;
        address target;
        uint votes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    Proposal[] public proposals;
    uint public proposalCount;

    event ProposalCreated(uint indexed proposalId, ProposalType pType, address indexed target);
    event Voted(uint indexed proposalId, address indexed voter);
    event ProposalExecuted(uint indexed proposalId);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can perform this action.");
        _;
    }

    constructor() {
        // The deployer is the first admin
        isAdmin[msg.sender] = true;
        admins.push(msg.sender);
        adminCount = 1;
    }

    function createProposal(ProposalType _pType, address _target) public onlyAdmin {
        require(_target != address(0), "Target address cannot be zero.");
        if (_pType == ProposalType.AddAdmin) {
            require(!isAdmin[_target], "User is already an admin.");
        } else { // RemoveAdmin
            require(isAdmin[_target], "User is not an admin.");
        }

        proposals.push(Proposal({
            pType: _pType,
            target: _target,
            votes: 0,
            executed: false
        }));
        proposalCount++;
        emit ProposalCreated(proposalCount - 1, _pType, _target);
    }

    function vote(uint _proposalId) public onlyAdmin {
        require(_proposalId < proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_proposalId, msg.sender);
    }

    function executeProposal(uint _proposalId) public onlyAdmin {
        require(_proposalId < proposalCount, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal has already been executed.");
        
        // Majority vote required
        require(p.votes > adminCount / 2, "Majority vote not reached.");

        p.executed = true;
        if (p.pType == ProposalType.AddAdmin) {
            isAdmin[p.target] = true;
            admins.push(p.target);
            adminCount++;
        } else { // RemoveAdmin
            isAdmin[p.target] = false;
            // Removing from the admins array is more complex and gas-intensive.
            // For simplicity, we'll just mark them as not admin. A more robust implementation
            // would handle array cleanup.
            adminCount--;
        }
        emit ProposalExecuted(_proposalId);
    }

    function getAdmins() public view returns (address[] memory) {
        return admins;
    }
}
