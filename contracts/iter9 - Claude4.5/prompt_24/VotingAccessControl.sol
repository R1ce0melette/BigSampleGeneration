// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    struct Proposal {
        uint256 id;
        address targetAdmin;
        bool isAddProposal; // true for add, false for remove
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 expiresAt;
        bool executed;
        bool cancelled;
        address proposer;
    }
    
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    
    address[] public admins;
    address[] public members;
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public quorumPercentage = 50; // 50% of members must vote
    uint256 public approvalPercentage = 66; // 66% approval needed
    
    address public founder;
    
    // Events
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint256 indexed proposalId, address indexed target, bool isAddProposal);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool approved);
    event ProposalCancelled(uint256 indexed proposalId);
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(isMember[msg.sender], "Only member can call this function");
        _;
    }
    
    modifier onlyFounder() {
        require(msg.sender == founder, "Only founder can call this function");
        _;
    }
    
    constructor() {
        founder = msg.sender;
        isAdmin[msg.sender] = true;
        isMember[msg.sender] = true;
        admins.push(msg.sender);
        members.push(msg.sender);
    }
    
    /**
     * @dev Add a new member (admin only)
     * @param _member The address of the new member
     */
    function addMember(address _member) external onlyAdmin {
        require(_member != address(0), "Invalid member address");
        require(!isMember[_member], "Already a member");
        
        isMember[_member] = true;
        members.push(_member);
        
        emit MemberAdded(_member);
    }
    
    /**
     * @dev Remove a member (admin only)
     * @param _member The address of the member to remove
     */
    function removeMember(address _member) external onlyAdmin {
        require(_member != address(0), "Invalid member address");
        require(isMember[_member], "Not a member");
        require(!isAdmin[_member], "Cannot remove admin as member");
        
        isMember[_member] = false;
        
        emit MemberRemoved(_member);
    }
    
    /**
     * @dev Create a proposal to add an admin
     * @param _admin The address to add as admin
     */
    function proposeAddAdmin(address _admin) external onlyMember {
        require(_admin != address(0), "Invalid admin address");
        require(isMember[_admin], "Target must be a member first");
        require(!isAdmin[_admin], "Already an admin");
        
        _createProposal(_admin, true);
    }
    
    /**
     * @dev Create a proposal to remove an admin
     * @param _admin The address to remove as admin
     */
    function proposeRemoveAdmin(address _admin) external onlyMember {
        require(_admin != address(0), "Invalid admin address");
        require(isAdmin[_admin], "Not an admin");
        require(_admin != founder, "Cannot remove founder");
        
        uint256 adminCount = 0;
        for (uint256 i = 0; i < admins.length; i++) {
            if (isAdmin[admins[i]]) {
                adminCount++;
            }
        }
        require(adminCount > 1, "Cannot remove the last admin");
        
        _createProposal(_admin, false);
    }
    
    /**
     * @dev Internal function to create a proposal
     * @param _target The target address
     * @param _isAddProposal True for add, false for remove
     */
    function _createProposal(address _target, bool _isAddProposal) private {
        proposalCount++;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            targetAdmin: _target,
            isAddProposal: _isAddProposal,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + VOTING_PERIOD,
            executed: false,
            cancelled: false,
            proposer: msg.sender
        });
        
        emit ProposalCreated(proposalCount, _target, _isAddProposal);
    }
    
    /**
     * @dev Vote on a proposal
     * @param _proposalId The ID of the proposal
     * @param _support True to support, false to oppose
     */
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp <= proposal.expiresAt, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal was cancelled");
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
     * @dev Execute a proposal after voting period
     * @param _proposalId The ID of the proposal
     */
    function executeProposal(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp > proposal.expiresAt, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal was cancelled");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 memberCount = _getActiveMemberCount();
        
        // Check quorum
        bool quorumReached = (totalVotes * 100) >= (memberCount * quorumPercentage);
        
        // Check approval
        bool approved = false;
        if (quorumReached && totalVotes > 0) {
            approved = (proposal.votesFor * 100) >= (totalVotes * approvalPercentage);
        }
        
        proposal.executed = true;
        
        if (approved) {
            if (proposal.isAddProposal) {
                // Add admin
                isAdmin[proposal.targetAdmin] = true;
                admins.push(proposal.targetAdmin);
                emit AdminAdded(proposal.targetAdmin);
            } else {
                // Remove admin
                isAdmin[proposal.targetAdmin] = false;
                emit AdminRemoved(proposal.targetAdmin);
            }
        }
        
        emit ProposalExecuted(_proposalId, approved);
    }
    
    /**
     * @dev Cancel a proposal (only proposer or admin)
     * @param _proposalId The ID of the proposal
     */
    function cancelProposal(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal already cancelled");
        require(
            msg.sender == proposal.proposer || isAdmin[msg.sender],
            "Only proposer or admin can cancel"
        );
        
        proposal.cancelled = true;
        
        emit ProposalCancelled(_proposalId);
    }
    
    /**
     * @dev Get active member count
     * @return The number of active members
     */
    function _getActiveMemberCount() private view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                count++;
            }
        }
        return count;
    }
    
    /**
     * @dev Get proposal details
     * @param _proposalId The ID of the proposal
     * @return All proposal details
     */
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address targetAdmin,
        bool isAddProposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 createdAt,
        uint256 expiresAt,
        bool executed,
        bool cancelled,
        address proposer
    ) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal memory proposal = proposals[_proposalId];
        
        return (
            proposal.id,
            proposal.targetAdmin,
            proposal.isAddProposal,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.expiresAt,
            proposal.executed,
            proposal.cancelled,
            proposal.proposer
        );
    }
    
    /**
     * @dev Get all admins
     * @return Array of admin addresses
     */
    function getAdmins() external view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < admins.length; i++) {
            if (isAdmin[admins[i]]) {
                count++;
            }
        }
        
        address[] memory activeAdmins = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < admins.length; i++) {
            if (isAdmin[admins[i]]) {
                activeAdmins[index] = admins[i];
                index++;
            }
        }
        
        return activeAdmins;
    }
    
    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getMembers() external view returns (address[] memory) {
        uint256 count = _getActiveMemberCount();
        
        address[] memory activeMembers = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                activeMembers[index] = members[i];
                index++;
            }
        }
        
        return activeMembers;
    }
    
    /**
     * @dev Update voting parameters (founder only)
     * @param _quorumPercentage New quorum percentage
     * @param _approvalPercentage New approval percentage
     */
    function updateVotingParameters(
        uint256 _quorumPercentage,
        uint256 _approvalPercentage
    ) external onlyFounder {
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Invalid quorum percentage");
        require(_approvalPercentage > 50 && _approvalPercentage <= 100, "Invalid approval percentage");
        
        quorumPercentage = _quorumPercentage;
        approvalPercentage = _approvalPercentage;
    }
}
