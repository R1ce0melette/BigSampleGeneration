// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingAccessControl
 * @dev A voting-based access control system where members can vote to add or remove admins
 */
contract VotingAccessControl {
    address public owner;
    
    // Roles
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    
    address[] public admins;
    address[] public members;
    
    // Proposal types
    enum ProposalType {
        ADD_ADMIN,
        REMOVE_ADMIN,
        ADD_MEMBER,
        REMOVE_MEMBER
    }
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address targetAddress;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 deadline;
        bool executed;
        bool passed;
    }
    
    // State variables
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    // Voting parameters
    uint256 public votingPeriod = 3 days;
    uint256 public quorumPercentage = 50; // 50% of members must vote
    uint256 public approvalPercentage = 66; // 66% approval needed
    
    // Events
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed targetAddress, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    
    // Modifiers
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
    
    /**
     * @dev Constructor sets the owner as the first admin and member
     */
    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        isMember[msg.sender] = true;
        admins.push(msg.sender);
        members.push(msg.sender);
        
        emit AdminAdded(msg.sender);
        emit MemberAdded(msg.sender);
    }
    
    /**
     * @dev Add a member (only admin)
     * @param member The address to add as member
     */
    function addMemberByAdmin(address member) external onlyAdmin {
        require(member != address(0), "Invalid member address");
        require(!isMember[member], "Already a member");
        
        isMember[member] = true;
        members.push(member);
        
        emit MemberAdded(member);
    }
    
    /**
     * @dev Create a proposal
     * @param proposalType The type of proposal
     * @param targetAddress The address to be added or removed
     * @return proposalId The ID of the created proposal
     */
    function createProposal(ProposalType proposalType, address targetAddress) external onlyMember returns (uint256) {
        require(targetAddress != address(0), "Invalid target address");
        
        // Validate proposal type
        if (proposalType == ProposalType.ADD_ADMIN) {
            require(!isAdmin[targetAddress], "Already an admin");
            require(isMember[targetAddress], "Target must be a member to become admin");
        } else if (proposalType == ProposalType.REMOVE_ADMIN) {
            require(isAdmin[targetAddress], "Not an admin");
            require(targetAddress != owner, "Cannot remove owner");
        } else if (proposalType == ProposalType.ADD_MEMBER) {
            require(!isMember[targetAddress], "Already a member");
        } else if (proposalType == ProposalType.REMOVE_MEMBER) {
            require(isMember[targetAddress], "Not a member");
            require(targetAddress != owner, "Cannot remove owner");
        }
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: proposalType,
            targetAddress: targetAddress,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            deadline: block.timestamp + votingPeriod,
            executed: false,
            passed: false
        });
        
        emit ProposalCreated(proposalId, proposalType, targetAddress, msg.sender);
        
        return proposalId;
    }
    
    /**
     * @dev Vote on a proposal
     * @param proposalId The ID of the proposal
     * @param support True to vote for, false to vote against
     */
    function vote(uint256 proposalId, bool support) external onlyMember {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");
        
        hasVoted[proposalId][msg.sender] = true;
        
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(proposalId, msg.sender, support);
    }
    
    /**
     * @dev Execute a proposal after voting period
     * @param proposalId The ID of the proposal
     */
    function executeProposal(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 memberCount = members.length;
        
        // Check quorum
        bool quorumReached = (totalVotes * 100) >= (memberCount * quorumPercentage);
        
        // Check approval
        bool approved = false;
        if (totalVotes > 0) {
            approved = (proposal.votesFor * 100) >= (totalVotes * approvalPercentage);
        }
        
        proposal.executed = true;
        proposal.passed = quorumReached && approved;
        
        if (proposal.passed) {
            _executeAction(proposal.proposalType, proposal.targetAddress);
        }
        
        emit ProposalExecuted(proposalId, proposal.passed);
    }
    
    /**
     * @dev Internal function to execute the proposal action
     * @param proposalType The type of proposal
     * @param targetAddress The target address
     */
    function _executeAction(ProposalType proposalType, address targetAddress) internal {
        if (proposalType == ProposalType.ADD_ADMIN) {
            isAdmin[targetAddress] = true;
            admins.push(targetAddress);
            emit AdminAdded(targetAddress);
        } else if (proposalType == ProposalType.REMOVE_ADMIN) {
            isAdmin[targetAddress] = false;
            _removeFromArray(admins, targetAddress);
            emit AdminRemoved(targetAddress);
        } else if (proposalType == ProposalType.ADD_MEMBER) {
            isMember[targetAddress] = true;
            members.push(targetAddress);
            emit MemberAdded(targetAddress);
        } else if (proposalType == ProposalType.REMOVE_MEMBER) {
            isMember[targetAddress] = false;
            _removeFromArray(members, targetAddress);
            // Also remove from admin if they are one
            if (isAdmin[targetAddress]) {
                isAdmin[targetAddress] = false;
                _removeFromArray(admins, targetAddress);
                emit AdminRemoved(targetAddress);
            }
            emit MemberRemoved(targetAddress);
        }
    }
    
    /**
     * @dev Internal function to remove an address from an array
     * @param array The array to remove from
     * @param addr The address to remove
     */
    function _removeFromArray(address[] storage array, address addr) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Get proposal details
     * @param proposalId The ID of the proposal
     * @return id Proposal ID
     * @return proposalType Type of proposal
     * @return targetAddress Target address
     * @return proposer Proposer address
     * @return votesFor Votes for
     * @return votesAgainst Votes against
     * @return createdAt Creation timestamp
     * @return deadline Voting deadline
     * @return executed Whether executed
     * @return passed Whether passed
     */
    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address targetAddress,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 createdAt,
        uint256 deadline,
        bool executed,
        bool passed
    ) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposalType,
            proposal.targetAddress,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.deadline,
            proposal.executed,
            proposal.passed
        );
    }
    
    /**
     * @dev Get all admins
     * @return Array of admin addresses
     */
    function getAdmins() external view returns (address[] memory) {
        return admins;
    }
    
    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    /**
     * @dev Get admin count
     * @return The number of admins
     */
    function getAdminCount() external view returns (uint256) {
        return admins.length;
    }
    
    /**
     * @dev Get member count
     * @return The number of members
     */
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }
    
    /**
     * @dev Get active proposals
     * @return Array of active proposal IDs
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (!proposals[i].executed && block.timestamp < proposals[i].deadline) {
                activeCount++;
            }
        }
        
        uint256[] memory activeProposalIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (!proposals[i].executed && block.timestamp < proposals[i].deadline) {
                activeProposalIds[index] = i;
                index++;
            }
        }
        
        return activeProposalIds;
    }
    
    /**
     * @dev Update voting period (only owner)
     * @param newPeriod The new voting period in seconds
     */
    function setVotingPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Voting period must be greater than 0");
        votingPeriod = newPeriod;
    }
    
    /**
     * @dev Update quorum percentage (only owner)
     * @param newPercentage The new quorum percentage
     */
    function setQuorumPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage > 0 && newPercentage <= 100, "Invalid percentage");
        quorumPercentage = newPercentage;
    }
    
    /**
     * @dev Update approval percentage (only owner)
     * @param newPercentage The new approval percentage
     */
    function setApprovalPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage > 0 && newPercentage <= 100, "Invalid percentage");
        approvalPercentage = newPercentage;
    }
    
    /**
     * @dev Check if caller has voted on a proposal
     * @param proposalId The ID of the proposal
     * @return True if caller has voted, false otherwise
     */
    function haveIVoted(uint256 proposalId) external view returns (bool) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        return hasVoted[proposalId][msg.sender];
    }
    
    /**
     * @dev Check if a proposal can be executed
     * @param proposalId The ID of the proposal
     * @return True if can be executed, false otherwise
     */
    function canExecuteProposal(uint256 proposalId) external view returns (bool) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal memory proposal = proposals[proposalId];
        
        return !proposal.executed && block.timestamp >= proposal.deadline;
    }
}
