// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    address public owner;
    
    enum ProposalType { ADD_ADMIN, REMOVE_ADMIN }
    enum ProposalStatus { PENDING, APPROVED, REJECTED, EXECUTED }
    
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address targetAddress;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 deadline;
        ProposalStatus status;
        bool executed;
    }

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    
    address[] public admins;
    address[] public members;
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    uint256 public votingPeriod = 3 days;
    uint256 public quorumPercentage = 51; // 51% required

    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed targetAddress);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only member can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        isMember[msg.sender] = true;
        admins.push(msg.sender);
        members.push(msg.sender);
    }

    function addMember(address member) external onlyAdmin {
        require(member != address(0), "Invalid address");
        require(!isMember[member], "Already a member");
        
        isMember[member] = true;
        members.push(member);
        
        emit MemberAdded(member);
    }

    function removeMember(address member) external onlyAdmin {
        require(isMember[member], "Not a member");
        require(!isAdmin[member], "Cannot remove admin as member");
        
        isMember[member] = false;
        
        // Remove from members array
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        
        emit MemberRemoved(member);
    }

    function proposeAddAdmin(address candidate) external onlyMember {
        require(candidate != address(0), "Invalid address");
        require(isMember[candidate], "Candidate must be a member");
        require(!isAdmin[candidate], "Already an admin");
        
        _createProposal(ProposalType.ADD_ADMIN, candidate);
    }

    function proposeRemoveAdmin(address admin) external onlyMember {
        require(isAdmin[admin], "Target is not an admin");
        require(admin != owner, "Cannot remove owner");
        require(admins.length > 1, "Cannot remove the last admin");
        
        _createProposal(ProposalType.REMOVE_ADMIN, admin);
    }

    function _createProposal(ProposalType proposalType, address targetAddress) private {
        proposalCount++;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposalType: proposalType,
            targetAddress: targetAddress,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            deadline: block.timestamp + votingPeriod,
            status: ProposalStatus.PENDING,
            executed: false
        });
        
        emit ProposalCreated(proposalCount, proposalType, targetAddress);
    }

    function vote(uint256 proposalId, bool support) external onlyMember {
        require(proposalId > 0 && proposalId <= proposalCount, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not pending");
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        hasVoted[proposalId][msg.sender] = true;
        
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not pending");
        require(block.timestamp > proposal.deadline, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumRequired = (members.length * quorumPercentage) / 100;
        
        if (totalVotes < quorumRequired) {
            proposal.status = ProposalStatus.REJECTED;
        } else if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.APPROVED;
            _executeApprovedProposal(proposal);
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        
        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.status);
    }

    function _executeApprovedProposal(Proposal storage proposal) private {
        if (proposal.proposalType == ProposalType.ADD_ADMIN) {
            if (!isAdmin[proposal.targetAddress]) {
                isAdmin[proposal.targetAddress] = true;
                admins.push(proposal.targetAddress);
                emit AdminAdded(proposal.targetAddress);
            }
        } else if (proposal.proposalType == ProposalType.REMOVE_ADMIN) {
            if (isAdmin[proposal.targetAddress] && proposal.targetAddress != owner) {
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
        }
    }

    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address targetAddress,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 deadline,
        ProposalStatus status
    ) {
        require(proposalId > 0 && proposalId <= proposalCount, "Proposal does not exist");
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposalType,
            proposal.targetAddress,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.deadline,
            proposal.status
        );
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    function getPendingProposals() external view returns (uint256[] memory) {
        uint256 pendingCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING) {
                pendingCount++;
            }
        }
        
        uint256[] memory pendingProposalIds = new uint256[](pendingCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING) {
                pendingProposalIds[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return pendingProposalIds;
    }
}
