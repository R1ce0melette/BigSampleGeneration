// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    address public owner;
    
    enum ProposalType { ADD_ADMIN, REMOVE_ADMIN }
    enum ProposalStatus { PENDING, APPROVED, REJECTED, EXECUTED }
    
    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address targetAddress;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 deadline;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
    }
    
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    address[] public admins;
    address[] public members;
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    
    uint256 public votingPeriod = 3 days;
    uint256 public quorumPercentage = 50; // 50% of members must vote
    
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed targetAddress, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(isMember[msg.sender], "Only member can call this function");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        isMember[msg.sender] = true;
        admins.push(msg.sender);
        members.push(msg.sender);
    }
    
    function addMember(address _member) external onlyAdmin {
        require(_member != address(0), "Member address cannot be zero");
        require(!isMember[_member], "Address is already a member");
        
        isMember[_member] = true;
        members.push(_member);
        
        emit MemberAdded(_member);
    }
    
    function removeMember(address _member) external onlyAdmin {
        require(isMember[_member], "Address is not a member");
        require(_member != owner, "Cannot remove owner");
        
        isMember[_member] = false;
        
        // Remove from members array
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        
        // If they were admin, remove admin status
        if (isAdmin[_member]) {
            isAdmin[_member] = false;
            for (uint256 i = 0; i < admins.length; i++) {
                if (admins[i] == _member) {
                    admins[i] = admins[admins.length - 1];
                    admins.pop();
                    break;
                }
            }
        }
        
        emit MemberRemoved(_member);
    }
    
    function createProposal(ProposalType _proposalType, address _targetAddress) external onlyMember returns (uint256) {
        require(_targetAddress != address(0), "Target address cannot be zero");
        require(_targetAddress != owner, "Cannot propose changes for owner");
        
        if (_proposalType == ProposalType.ADD_ADMIN) {
            require(isMember[_targetAddress], "Target must be a member to become admin");
            require(!isAdmin[_targetAddress], "Target is already an admin");
        } else if (_proposalType == ProposalType.REMOVE_ADMIN) {
            require(isAdmin[_targetAddress], "Target is not an admin");
        }
        
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.proposalType = _proposalType;
        newProposal.targetAddress = _targetAddress;
        newProposal.proposer = msg.sender;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.createdAt = block.timestamp;
        newProposal.deadline = block.timestamp + votingPeriod;
        newProposal.status = ProposalStatus.PENDING;
        
        emit ProposalCreated(proposalCount, _proposalType, _targetAddress, msg.sender);
        
        return proposalCount;
    }
    
    function vote(uint256 _proposalId, bool _support) external onlyMember proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not pending");
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support);
    }
    
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not pending");
        require(block.timestamp > proposal.deadline, "Voting period has not ended");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = (members.length * quorumPercentage) / 100;
        
        if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.APPROVED;
            
            if (proposal.proposalType == ProposalType.ADD_ADMIN) {
                isAdmin[proposal.targetAddress] = true;
                admins.push(proposal.targetAddress);
                emit AdminAdded(proposal.targetAddress);
            } else if (proposal.proposalType == ProposalType.REMOVE_ADMIN) {
                isAdmin[proposal.targetAddress] = false;
                for (uint256 i = 0; i < admins.length; i++) {
                    if (admins[i] == proposal.targetAddress) {
                        admins[i] = admins[admins.length - 1];
                        admins.pop();
                        break;
                    }
                }
                emit AdminRemoved(proposal.targetAddress);
            }
            
            proposal.status = ProposalStatus.EXECUTED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        
        emit ProposalExecuted(_proposalId, proposal.status);
    }
    
    function getProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (
        ProposalType proposalType,
        address targetAddress,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 createdAt,
        uint256 deadline,
        ProposalStatus status
    ) {
        Proposal storage proposal = proposals[_proposalId];
        
        return (
            proposal.proposalType,
            proposal.targetAddress,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.deadline,
            proposal.status
        );
    }
    
    function hasVoted(uint256 _proposalId, address _voter) external view proposalExists(_proposalId) returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }
    
    function getAdmins() external view returns (address[] memory) {
        return admins;
    }
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getAdminCount() external view returns (uint256) {
        return admins.length;
    }
    
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }
    
    function updateVotingPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "Voting period must be greater than 0");
        votingPeriod = _newPeriod;
    }
    
    function updateQuorumPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage > 0 && _newPercentage <= 100, "Percentage must be between 1 and 100");
        quorumPercentage = _newPercentage;
    }
}
