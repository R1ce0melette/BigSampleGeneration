// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingAccessControl
 * @dev A voting-based access control system where members can vote to add or remove admins
 */
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
        uint256 votingEndsAt;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
    }
    
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    
    uint256 public adminCount;
    uint256 public memberCount;
    uint256 public proposalCount;
    
    mapping(uint256 => Proposal) public proposals;
    
    uint256 public votingDuration = 3 days;
    uint256 public quorumPercentage = 50; // 50% of members must vote
    uint256 public approvalPercentage = 60; // 60% approval needed
    
    // Events
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed targetAddress, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool inFavor);
    event ProposalExecuted(uint256 indexed proposalId, bool approved);
    
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
        adminCount = 1;
        memberCount = 1;
    }
    
    /**
     * @dev Add a member (admin only)
     * @param member The address to add as member
     */
    function addMember(address member) external onlyAdmin {
        require(member != address(0), "Invalid address");
        require(!isMember[member], "Already a member");
        
        isMember[member] = true;
        memberCount++;
        
        emit MemberAdded(member);
    }
    
    /**
     * @dev Remove a member (admin only)
     * @param member The address to remove
     */
    function removeMember(address member) external onlyAdmin {
        require(isMember[member], "Not a member");
        require(!isAdmin[member], "Cannot remove admin as member");
        
        isMember[member] = false;
        memberCount--;
        
        emit MemberRemoved(member);
    }
    
    /**
     * @dev Create a proposal to add an admin
     * @param targetAddress The address to add as admin
     */
    function proposeAddAdmin(address targetAddress) external onlyMember {
        require(targetAddress != address(0), "Invalid address");
        require(!isAdmin[targetAddress], "Already an admin");
        require(isMember[targetAddress], "Target must be a member first");
        
        _createProposal(ProposalType.ADD_ADMIN, targetAddress);
    }
    
    /**
     * @dev Create a proposal to remove an admin
     * @param targetAddress The address to remove as admin
     */
    function proposeRemoveAdmin(address targetAddress) external onlyMember {
        require(isAdmin[targetAddress], "Not an admin");
        require(targetAddress != owner, "Cannot remove owner");
        require(adminCount > 1, "Cannot remove the last admin");
        
        _createProposal(ProposalType.REMOVE_ADMIN, targetAddress);
    }
    
    /**
     * @dev Internal function to create a proposal
     * @param proposalType The type of proposal
     * @param targetAddress The target address
     */
    function _createProposal(ProposalType proposalType, address targetAddress) internal {
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposalType = proposalType;
        newProposal.targetAddress = targetAddress;
        newProposal.proposer = msg.sender;
        newProposal.createdAt = block.timestamp;
        newProposal.votingEndsAt = block.timestamp + votingDuration;
        newProposal.status = ProposalStatus.PENDING;
        
        emit ProposalCreated(proposalCount, proposalType, targetAddress, msg.sender);
    }
    
    /**
     * @dev Vote on a proposal
     * @param proposalId The ID of the proposal
     * @param inFavor True to vote in favor, false to vote against
     */
    function vote(uint256 proposalId, bool inFavor) external onlyMember {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not pending");
        require(block.timestamp <= proposal.votingEndsAt, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (inFavor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(proposalId, msg.sender, inFavor);
    }
    
    /**
     * @dev Execute a proposal after voting period ends
     * @param proposalId The ID of the proposal
     */
    function executeProposal(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not pending");
        require(block.timestamp > proposal.votingEndsAt, "Voting period has not ended");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumRequired = (memberCount * quorumPercentage) / 100;
        
        // Check if quorum is met
        if (totalVotes < quorumRequired) {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalExecuted(proposalId, false);
            return;
        }
        
        // Check if approval threshold is met
        uint256 approvalRequired = (totalVotes * approvalPercentage) / 100;
        bool approved = proposal.votesFor >= approvalRequired;
        
        if (approved) {
            proposal.status = ProposalStatus.APPROVED;
            
            // Execute the proposal
            if (proposal.proposalType == ProposalType.ADD_ADMIN) {
                if (!isAdmin[proposal.targetAddress] && isMember[proposal.targetAddress]) {
                    isAdmin[proposal.targetAddress] = true;
                    adminCount++;
                    emit AdminAdded(proposal.targetAddress);
                }
            } else if (proposal.proposalType == ProposalType.REMOVE_ADMIN) {
                if (isAdmin[proposal.targetAddress] && proposal.targetAddress != owner && adminCount > 1) {
                    isAdmin[proposal.targetAddress] = false;
                    adminCount--;
                    emit AdminRemoved(proposal.targetAddress);
                }
            }
            
            proposal.status = ProposalStatus.EXECUTED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        
        emit ProposalExecuted(proposalId, approved);
    }
    
    /**
     * @dev Get proposal details
     * @param proposalId The ID of the proposal
     * @return id Proposal ID
     * @return proposalType Type of proposal
     * @return targetAddress Target address
     * @return proposer Proposer address
     * @return votesFor Votes in favor
     * @return votesAgainst Votes against
     * @return createdAt Creation timestamp
     * @return votingEndsAt Voting end timestamp
     * @return status Proposal status
     */
    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address targetAddress,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 createdAt,
        uint256 votingEndsAt,
        ProposalStatus status
    ) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        
        return (
            proposal.id,
            proposal.proposalType,
            proposal.targetAddress,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.votingEndsAt,
            proposal.status
        );
    }
    
    /**
     * @dev Check if an address has voted on a proposal
     * @param proposalId The ID of the proposal
     * @param voter The address to check
     * @return True if voted, false otherwise
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        return proposals[proposalId].hasVoted[voter];
    }
    
    /**
     * @dev Get all pending proposals
     * @return Array of pending proposal IDs
     */
    function getPendingProposals() external view returns (uint256[] memory) {
        uint256 pendingCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING) {
                pendingCount++;
            }
        }
        
        uint256[] memory pendingProposals = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING) {
                pendingProposals[index] = i;
                index++;
            }
        }
        
        return pendingProposals;
    }
    
    /**
     * @dev Get all admins
     * @return Array of admin addresses (approximate, may include removed admins)
     */
    function getAdminCount() external view returns (uint256) {
        return adminCount;
    }
    
    /**
     * @dev Get member count
     * @return The number of members
     */
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }
    
    /**
     * @dev Update voting parameters (owner only)
     * @param _votingDuration New voting duration in seconds
     * @param _quorumPercentage New quorum percentage (0-100)
     * @param _approvalPercentage New approval percentage (0-100)
     */
    function updateVotingParameters(
        uint256 _votingDuration,
        uint256 _quorumPercentage,
        uint256 _approvalPercentage
    ) external onlyOwner {
        require(_votingDuration > 0, "Invalid voting duration");
        require(_quorumPercentage <= 100, "Quorum percentage must be <= 100");
        require(_approvalPercentage <= 100, "Approval percentage must be <= 100");
        
        votingDuration = _votingDuration;
        quorumPercentage = _quorumPercentage;
        approvalPercentage = _approvalPercentage;
    }
    
    /**
     * @dev Check if a proposal can be executed
     * @param proposalId The ID of the proposal
     * @return True if the proposal can be executed, false otherwise
     */
    function canExecuteProposal(uint256 proposalId) external view returns (bool) {
        if (proposalId == 0 || proposalId > proposalCount) {
            return false;
        }
        
        Proposal storage proposal = proposals[proposalId];
        return proposal.status == ProposalStatus.PENDING && block.timestamp > proposal.votingEndsAt;
    }
    
    /**
     * @dev Transfer ownership
     * @param newOwner The new owner's address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        
        // Remove admin status from old owner if they're not a regular admin
        if (owner != newOwner) {
            // Add new owner as admin and member
            if (!isAdmin[newOwner]) {
                isAdmin[newOwner] = true;
                adminCount++;
            }
            if (!isMember[newOwner]) {
                isMember[newOwner] = true;
                memberCount++;
            }
            
            owner = newOwner;
        }
    }
}
