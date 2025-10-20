// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingAccessControl
 * @dev A voting-based access control system where members can vote to add or remove admins
 */
contract VotingAccessControl {
    address public owner;
    
    enum ProposalType {
        ADD_ADMIN,
        REMOVE_ADMIN
    }
    
    enum ProposalStatus {
        PENDING,
        APPROVED,
        REJECTED,
        EXECUTED
    }
    
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address targetAddress;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 votingDeadline;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
    }
    
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    
    address[] private admins;
    address[] private members;
    
    uint256 private proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public quorumPercentage = 50; // 50% of members must vote
    uint256 public approvalPercentage = 60; // 60% of votes must be in favor
    
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    
    event ProposalCreated(
        uint256 indexed proposalId,
        ProposalType proposalType,
        address indexed targetAddress,
        address indexed proposer
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool inFavor
    );
    
    event ProposalExecuted(
        uint256 indexed proposalId,
        ProposalStatus status
    );
    
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
    
    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        isMember[msg.sender] = true;
        admins.push(msg.sender);
        members.push(msg.sender);
    }
    
    /**
     * @dev Add a new member (only admin)
     * @param member Address to add as member
     */
    function addMember(address member) external onlyAdmin {
        require(member != address(0), "Invalid address");
        require(!isMember[member], "Already a member");
        
        isMember[member] = true;
        members.push(member);
        
        emit MemberAdded(member);
    }
    
    /**
     * @dev Remove a member (only admin)
     * @param member Address to remove
     */
    function removeMember(address member) external onlyAdmin {
        require(isMember[member], "Not a member");
        require(member != owner, "Cannot remove owner");
        
        isMember[member] = false;
        
        // If they are an admin, remove admin status
        if (isAdmin[member]) {
            isAdmin[member] = false;
        }
        
        emit MemberRemoved(member);
    }
    
    /**
     * @dev Create a proposal to add an admin
     * @param targetAddress Address to be added as admin
     * @return proposalId The ID of the created proposal
     */
    function proposeAddAdmin(address targetAddress) external onlyMember returns (uint256) {
        require(targetAddress != address(0), "Invalid address");
        require(isMember[targetAddress], "Target must be a member");
        require(!isAdmin[targetAddress], "Already an admin");
        
        return _createProposal(ProposalType.ADD_ADMIN, targetAddress);
    }
    
    /**
     * @dev Create a proposal to remove an admin
     * @param targetAddress Address to be removed as admin
     * @return proposalId The ID of the created proposal
     */
    function proposeRemoveAdmin(address targetAddress) external onlyMember returns (uint256) {
        require(targetAddress != address(0), "Invalid address");
        require(isAdmin[targetAddress], "Not an admin");
        require(targetAddress != owner, "Cannot remove owner");
        
        return _createProposal(ProposalType.REMOVE_ADMIN, targetAddress);
    }
    
    /**
     * @dev Internal function to create a proposal
     * @param proposalType Type of proposal
     * @param targetAddress Target address
     * @return proposalId The ID of the created proposal
     */
    function _createProposal(
        ProposalType proposalType,
        address targetAddress
    ) private returns (uint256) {
        proposalCounter++;
        uint256 proposalId = proposalCounter;
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = proposalType;
        newProposal.targetAddress = targetAddress;
        newProposal.proposer = msg.sender;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.createdAt = block.timestamp;
        newProposal.votingDeadline = block.timestamp + VOTING_PERIOD;
        newProposal.status = ProposalStatus.PENDING;
        
        emit ProposalCreated(proposalId, proposalType, targetAddress, msg.sender);
        
        return proposalId;
    }
    
    /**
     * @dev Vote on a proposal
     * @param proposalId The ID of the proposal
     * @param inFavor True to vote for, false to vote against
     */
    function vote(uint256 proposalId, bool inFavor) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.PENDING, "Proposal not pending");
        require(block.timestamp < proposal.votingDeadline, "Voting period ended");
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
     * @dev Execute a proposal after voting period
     * @param proposalId The ID of the proposal
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.PENDING, "Proposal not pending");
        require(block.timestamp >= proposal.votingDeadline, "Voting period not ended");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 memberCount = members.length;
        
        // Check quorum
        bool quorumReached = (totalVotes * 100) >= (memberCount * quorumPercentage);
        
        if (!quorumReached) {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalExecuted(proposalId, ProposalStatus.REJECTED);
            return;
        }
        
        // Check approval
        bool approved = (proposal.votesFor * 100) >= (totalVotes * approvalPercentage);
        
        if (approved) {
            proposal.status = ProposalStatus.APPROVED;
            
            // Execute the proposal
            if (proposal.proposalType == ProposalType.ADD_ADMIN) {
                if (!isAdmin[proposal.targetAddress] && isMember[proposal.targetAddress]) {
                    isAdmin[proposal.targetAddress] = true;
                    admins.push(proposal.targetAddress);
                    emit AdminAdded(proposal.targetAddress);
                }
            } else if (proposal.proposalType == ProposalType.REMOVE_ADMIN) {
                if (isAdmin[proposal.targetAddress] && proposal.targetAddress != owner) {
                    isAdmin[proposal.targetAddress] = false;
                    emit AdminRemoved(proposal.targetAddress);
                }
            }
            
            proposal.status = ProposalStatus.EXECUTED;
            emit ProposalExecuted(proposalId, ProposalStatus.EXECUTED);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalExecuted(proposalId, ProposalStatus.REJECTED);
        }
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
     * @return votingDeadline Deadline timestamp
     * @return status Current status
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address targetAddress,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 createdAt,
        uint256 votingDeadline,
        ProposalStatus status
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        
        return (
            proposal.id,
            proposal.proposalType,
            proposal.targetAddress,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.votingDeadline,
            proposal.status
        );
    }
    
    /**
     * @dev Check if an address has voted on a proposal
     * @param proposalId The ID of the proposal
     * @param voter The address to check
     * @return Whether the address has voted
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        require(proposals[proposalId].id != 0, "Proposal does not exist");
        return proposals[proposalId].hasVoted[voter];
    }
    
    /**
     * @dev Get all admins
     * @return Array of admin addresses
     */
    function getAdmins() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count current admins
        for (uint256 i = 0; i < admins.length; i++) {
            if (isAdmin[admins[i]]) {
                count++;
            }
        }
        
        // Create array and populate
        address[] memory currentAdmins = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < admins.length; i++) {
            if (isAdmin[admins[i]]) {
                currentAdmins[index] = admins[i];
                index++;
            }
        }
        
        return currentAdmins;
    }
    
    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getMembers() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count current members
        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                count++;
            }
        }
        
        // Create array and populate
        address[] memory currentMembers = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                currentMembers[index] = members[i];
                index++;
            }
        }
        
        return currentMembers;
    }
    
    /**
     * @dev Get pending proposals
     * @return Array of pending proposal IDs
     */
    function getPendingProposals() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count pending proposals
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.PENDING) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory pendingProposals = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.PENDING) {
                pendingProposals[index] = i;
                index++;
            }
        }
        
        return pendingProposals;
    }
    
    /**
     * @dev Get total number of proposals
     * @return The total count
     */
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter;
    }
    
    /**
     * @dev Update quorum percentage (only owner)
     * @param newQuorum New quorum percentage
     */
    function updateQuorum(uint256 newQuorum) external onlyOwner {
        require(newQuorum > 0 && newQuorum <= 100, "Invalid quorum percentage");
        quorumPercentage = newQuorum;
    }
    
    /**
     * @dev Update approval percentage (only owner)
     * @param newApproval New approval percentage
     */
    function updateApprovalPercentage(uint256 newApproval) external onlyOwner {
        require(newApproval > 0 && newApproval <= 100, "Invalid approval percentage");
        approvalPercentage = newApproval;
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        
        // Remove old owner from admin if different
        if (newOwner != owner) {
            isAdmin[owner] = false;
        }
        
        owner = newOwner;
        
        // Ensure new owner is admin and member
        if (!isAdmin[newOwner]) {
            isAdmin[newOwner] = true;
            admins.push(newOwner);
        }
        
        if (!isMember[newOwner]) {
            isMember[newOwner] = true;
            members.push(newOwner);
        }
    }
}
