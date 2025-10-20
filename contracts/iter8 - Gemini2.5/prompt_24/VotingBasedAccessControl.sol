// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VotingBasedAccessControl
 * @dev A contract where members vote to manage a list of admins.
 * Initial members are set at deployment.
 */
contract VotingBasedAccessControl {
    enum ProposalType { AddAdmin, RemoveAdmin }

    struct Proposal {
        ProposalType pType;
        address target;
        uint256 votes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    address public owner;
    mapping(address => bool) public isMember;
    mapping(address => bool) public isAdmin;
    uint256 public memberCount;
    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;

    event MemberAdded(address indexed newMember);
    event MemberRemoved(address indexed removedMember);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);
    event ProposalCreated(uint256 indexed proposalId, ProposalType pType, address indexed target);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can call this function.");
        _;
    }
    
    constructor(address[] memory _initialMembers) {
        owner = msg.sender;
        for (uint i = 0; i < _initialMembers.length; i++) {
            require(!isMember[_initialMembers[i]], "Duplicate initial member.");
            isMember[_initialMembers[i]] = true;
            memberCount++;
            emit MemberAdded(_initialMembers[i]);
        }
        // The deployer is an admin by default
        isAdmin[msg.sender] = true;
        emit AdminAdded(msg.sender);
    }

    function createProposal(ProposalType _pType, address _target) external onlyMember {
        require(_target != address(0), "Target address cannot be zero.");
        if (_pType == ProposalType.AddAdmin) {
            require(!isAdmin[_target], "Address is already an admin.");
        } else { // RemoveAdmin
            require(isAdmin[_target], "Address is not an admin.");
        }

        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.pType = _pType;
        newProposal.target = _target;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalCounter, _pType, _target);
    }

    function vote(uint256 _proposalId) external onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Proposal does not exist.");
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_proposalId, msg.sender);

        // Check if the proposal passes (more than 50% of members)
        if (p.votes * 2 > memberCount) {
            executeProposal(_proposalId);
        }
    }

    function executeProposal(uint256 _proposalId) private {
        Proposal storage p = proposals[_proposalId];
        p.executed = true;

        if (p.pType == ProposalType.AddAdmin) {
            isAdmin[p.target] = true;
            // New admins also become members if they aren't already
            if (!isMember[p.target]) {
                isMember[p.target] = true;
                memberCount++;
                emit MemberAdded(p.target);
            }
            emit AdminAdded(p.target);
        } else { // RemoveAdmin
            isAdmin[p.target] = false;
            emit AdminRemoved(p.target);
        }
        emit ProposalExecuted(_proposalId);
    }

    // A function protected by the admin role
    function adminOnlyFunction() external view onlyAdmin returns (string memory) {
        return "Welcome, admin!";
    }
}
