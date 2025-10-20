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
        uint256 deadline;
        ProposalStatus status;
        bool executed;
    }
    
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    
    uint256 public adminCount;
    uint256 public memberCount;
    uint256 public proposalCount;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    uint256 public votingPeriod = 7 days;
    uint256 public quorumPercentage = 51; // 51% required to pass
    
    // Events
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed targetAddress, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool approved);
    
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
        adminCount = 1;
        memberCount = 1;
    }
    
    /**
     * @dev Adds a new member (only admin can add)
     * @param _member The address to add as member
     */
    function addMember(address _member) external onlyAdmin {
        require(_member != address(0), "Invalid address");
        require(!isMember[_member], "Already a member");
        
        isMember[_member] = true;
        memberCount++;
        
        emit MemberAdded(_member);
    }
    
    /**
     * @dev Removes a member (only admin can remove)
     * @param _member The address to remove
     */
    function removeMember(address _member) external onlyAdmin {
        require(isMember[_member], "Not a member");
        require(!isAdmin[_member], "Cannot remove admin, remove admin status first");
        
        isMember[_member] = false;
        memberCount--;
        
        emit MemberRemoved(_member);
    }
    
    /**
     * @dev Creates a proposal to add an admin
     * @param _candidate The address to propose as admin
     */
    function proposeAddAdmin(address _candidate) external onlyMember {
        require(_candidate != address(0), "Invalid address");
        require(isMember[_candidate], "Candidate must be a member");
        require(!isAdmin[_candidate], "Already an admin");
        
        _createProposal(ProposalType.ADD_ADMIN, _candidate);
    }
    
    /**
     * @dev Creates a proposal to remove an admin
     * @param _admin The address to propose for removal
     */
    function proposeRemoveAdmin(address _admin) external onlyMember {
        require(isAdmin[_admin], "Not an admin");
        require(_admin != owner, "Cannot remove owner");
        require(adminCount > 1, "Cannot remove the last admin");
        
        _createProposal(ProposalType.REMOVE_ADMIN, _admin);
    }
    
    /**
     * @dev Internal function to create a proposal
     * @param _proposalType The type of proposal
     * @param _targetAddress The target address
     */
    function _createProposal(ProposalType _proposalType, address _targetAddress) private {
        proposalCount++;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposalType: _proposalType,
            targetAddress: _targetAddress,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            deadline: block.timestamp + votingPeriod,
            status: ProposalStatus.PENDING,
            executed: false
        });
        
        emit ProposalCreated(proposalCount, _proposalType, _targetAddress, msg.sender);
    }
    
    /**
     * @dev Allows members to vote on a proposal
     * @param _proposalId The ID of the proposal
     * @param _support True to vote for, false to vote against
     */
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal not pending");
        require(block.timestamp <= proposal.deadline, "Voting period ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        
        hasVoted[_proposalId][msg.sender] = true;
        
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support);
    }
    
    /**
     * @dev Executes a proposal after voting period ends
     * @param _proposalId The ID of the proposal
     */
    function executeProposal(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.PENDING, "Proposal not pending");
        require(block.timestamp > proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredVotes = (memberCount * quorumPercentage) / 100;
        
        bool approved = false;
        
        if (totalVotes >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
            approved = true;
            proposal.status = ProposalStatus.APPROVED;
            
            if (proposal.proposalType == ProposalType.ADD_ADMIN) {
                isAdmin[proposal.targetAddress] = true;
                adminCount++;
                emit AdminAdded(proposal.targetAddress);
            } else if (proposal.proposalType == ProposalType.REMOVE_ADMIN) {
                isAdmin[proposal.targetAddress] = false;
                adminCount--;
                emit AdminRemoved(proposal.targetAddress);
            }
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        
        proposal.executed = true;
        
        emit ProposalExecuted(_proposalId, approved);
    }
    
    /**
     * @dev Returns the details of a proposal
     * @param _proposalId The ID of the proposal
     * @return id The proposal ID
     * @return proposalType The type of proposal
     * @return targetAddress The target address
     * @return proposer The proposer's address
     * @return votesFor Votes in favor
     * @return votesAgainst Votes against
     * @return deadline The voting deadline
     * @return status The proposal status
     * @return executed Whether the proposal has been executed
     */
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address targetAddress,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 deadline,
        ProposalStatus status,
        bool executed
    ) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal memory proposal = proposals[_proposalId];
        
        return (
            proposal.id,
            proposal.proposalType,
            proposal.targetAddress,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.deadline,
            proposal.status,
            proposal.executed
        );
    }
    
    /**
     * @dev Returns all active (pending) proposals
     * @return Array of proposal IDs
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING && block.timestamp <= proposals[i].deadline) {
                activeCount++;
            }
        }
        
        uint256[] memory activeProposals = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING && block.timestamp <= proposals[i].deadline) {
                activeProposals[index] = i;
                index++;
            }
        }
        
        return activeProposals;
    }
    
    /**
     * @dev Returns proposals ready to be executed
     * @return Array of proposal IDs
     */
    function getExecutableProposals() external view returns (uint256[] memory) {
        uint256 executableCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING && 
                block.timestamp > proposals[i].deadline && 
                !proposals[i].executed) {
                executableCount++;
            }
        }
        
        uint256[] memory executableProposals = new uint256[](executableCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING && 
                block.timestamp > proposals[i].deadline && 
                !proposals[i].executed) {
                executableProposals[index] = i;
                index++;
            }
        }
        
        return executableProposals;
    }
    
    /**
     * @dev Checks if an address has voted on a proposal
     * @param _proposalId The ID of the proposal
     * @param _voter The address to check
     * @return True if voted, false otherwise
     */
    function hasUserVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        return hasVoted[_proposalId][_voter];
    }
    
    /**
     * @dev Updates the voting period (only owner)
     * @param _newPeriod The new voting period in seconds
     */
    function updateVotingPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "Period must be greater than 0");
        votingPeriod = _newPeriod;
    }
    
    /**
     * @dev Updates the quorum percentage (only owner)
     * @param _newPercentage The new quorum percentage
     */
    function updateQuorumPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage > 0 && _newPercentage <= 100, "Invalid percentage");
        quorumPercentage = _newPercentage;
    }
    
    /**
     * @dev Returns system statistics
     * @return totalMembers Total member count
     * @return totalAdmins Total admin count
     * @return totalProposals Total proposal count
     * @return activeProposals Count of active proposals
     */
    function getSystemStats() external view returns (
        uint256 totalMembers,
        uint256 totalAdmins,
        uint256 totalProposals,
        uint256 activeProposals
    ) {
        uint256 active = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PENDING && block.timestamp <= proposals[i].deadline) {
                active++;
            }
        }
        
        return (memberCount, adminCount, proposalCount, active);
    }
    
    /**
     * @dev Transfers ownership (only current owner)
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
        
        if (!isMember[_newOwner]) {
            isMember[_newOwner] = true;
            memberCount++;
        }
        
        if (!isAdmin[_newOwner]) {
            isAdmin[_newOwner] = true;
            adminCount++;
        }
    }
}
