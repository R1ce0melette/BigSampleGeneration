// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminVoting {

    enum ProposalType { AddAdmin, RemoveAdmin }

    struct Proposal {
        address candidate;
        ProposalType pType;
        uint256 voteCount;
        mapping(address => bool) voters;
        bool executed;
    }

    mapping(address => bool) public isMember;
    mapping(address => bool) public isAdmin;
    address[] public memberList;
    Proposal[] public proposals;

    uint256 public memberCount;
    uint256 public requiredVotesForMajority;

    event MemberAdded(address indexed newMember);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address indexed candidate, ProposalType pType);
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
        // The deployer is the first admin
        isAdmin[msg.sender] = true;
        
        // Add initial members
        for (uint i = 0; i < _initialMembers.length; i++) {
            addMember(_initialMembers[i]);
        }
        
        // Add the deployer as a member if not already in the list
        if (!isMember[msg.sender]) {
            addMember(msg.sender);
        }
    }

    function addMember(address _newMember) public onlyAdmin {
        require(!isMember[_newMember], "Address is already a member.");
        isMember[_newMember] = true;
        memberList.push(_newMember);
        memberCount++;
        _updateRequiredVotes();
        emit MemberAdded(_newMember);
    }

    function createProposal(address _candidate, ProposalType _pType) public onlyMember {
        if (_pType == ProposalType.AddAdmin) {
            require(!isAdmin[_candidate], "Candidate is already an admin.");
        } else if (_pType == ProposalType.RemoveAdmin) {
            require(isAdmin[_candidate], "Candidate is not an admin.");
        }

        uint256 proposalId = proposals.length;
        Proposal storage newProposal = proposals.push();
        newProposal.candidate = _candidate;
        newProposal.pType = _pType;
        
        emit ProposalCreated(proposalId, msg.sender, _candidate, _pType);
    }

    function vote(uint256 _proposalId) public onlyMember {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.voters[msg.sender], "You have already voted on this proposal.");

        p.voters[msg.sender] = true;
        p.voteCount++;
        emit Voted(_proposalId, msg.sender);
    }

    function executeProposal(uint256 _proposalId) public {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal has already been executed.");
        require(p.voteCount >= requiredVotesForMajority, "Proposal does not have enough votes to be executed.");

        p.executed = true;

        if (p.pType == ProposalType.AddAdmin) {
            isAdmin[p.candidate] = true;
            // Also make them a member if they aren't already
            if(!isMember[p.candidate]){
                addMember(p.candidate);
            }
            emit AdminAdded(p.candidate);
        } else if (p.pType == ProposalType.RemoveAdmin) {
            isAdmin[p.candidate] = false;
            emit AdminRemoved(p.candidate);
        }
        
        emit ProposalExecuted(_proposalId);
    }

    function _updateRequiredVotes() private {
        requiredVotesForMajority = (memberCount / 2) + 1;
    }

    function getProposal(uint256 _proposalId) public view returns (address, ProposalType, uint256, bool) {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        Proposal storage p = proposals[_proposalId];
        return (p.candidate, p.pType, p.voteCount, p.executed);
    }
}
