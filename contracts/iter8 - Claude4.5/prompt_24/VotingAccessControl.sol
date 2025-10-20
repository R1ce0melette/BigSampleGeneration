// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingAccessControl
 * @dev Voting-based access control system where members can vote to add or remove admins
 */
contract VotingAccessControl {
    // Proposal types
    enum ProposalType {
        AddAdmin,
        RemoveAdmin,
        AddMember,
        RemoveMember
    }

    // Proposal status
    enum ProposalStatus {
        Active,
        Passed,
        Rejected,
        Executed
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
        uint256 expiryTime;
        ProposalStatus status;
        bool executed;
    }

    // Member information
    struct MemberInfo {
        bool isMember;
        bool isAdmin;
        uint256 joinedAt;
        uint256 proposalsCreated;
        uint256 votesSubmitted;
    }

    // State variables
    address public owner;
    uint256 private proposalCounter;
    uint256 public votingPeriod; // Duration in seconds
    uint256 public quorumPercentage; // Percentage required for quorum (e.g., 50 for 50%)
    uint256 public approvalPercentage; // Percentage required for approval (e.g., 60 for 60%)
    
    mapping(address => MemberInfo) private members;
    mapping(address => bool) private admins;
    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => mapping(address => bool)) private hasVoted;
    mapping(uint256 => mapping(address => bool)) private voteChoice; // true = for, false = against
    
    address[] private memberList;
    address[] private adminList;
    uint256[] private allProposalIds;
    
    uint256 public memberCount;
    uint256 public adminCount;

    // Events
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed targetAddress, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event SettingsUpdated(uint256 votingPeriod, uint256 quorumPercentage, uint256 approvalPercentage);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Not a member");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCounter, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 proposalId) {
        require(proposals[proposalId].status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp < proposals[proposalId].expiryTime, "Proposal has expired");
        _;
    }

    constructor(
        uint256 _votingPeriod,
        uint256 _quorumPercentage,
        uint256 _approvalPercentage
    ) {
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Invalid quorum percentage");
        require(_approvalPercentage > 0 && _approvalPercentage <= 100, "Invalid approval percentage");
        
        owner = msg.sender;
        proposalCounter = 0;
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        approvalPercentage = _approvalPercentage;
        
        // Owner is first admin and member
        members[msg.sender] = MemberInfo({
            isMember: true,
            isAdmin: true,
            joinedAt: block.timestamp,
            proposalsCreated: 0,
            votesSubmitted: 0
        });
        admins[msg.sender] = true;
        memberList.push(msg.sender);
        adminList.push(msg.sender);
        memberCount = 1;
        adminCount = 1;
    }

    /**
     * @dev Create a proposal to add an admin
     * @param targetAddress Address to add as admin
     * @return proposalId ID of the created proposal
     */
    function proposeAddAdmin(address targetAddress) public onlyMember returns (uint256) {
        require(targetAddress != address(0), "Invalid target address");
        require(members[targetAddress].isMember, "Target must be a member first");
        require(!admins[targetAddress], "Already an admin");

        return _createProposal(ProposalType.AddAdmin, targetAddress);
    }

    /**
     * @dev Create a proposal to remove an admin
     * @param targetAddress Address to remove as admin
     * @return proposalId ID of the created proposal
     */
    function proposeRemoveAdmin(address targetAddress) public onlyMember returns (uint256) {
        require(targetAddress != address(0), "Invalid target address");
        require(admins[targetAddress], "Not an admin");
        require(targetAddress != owner, "Cannot remove owner");
        require(adminCount > 1, "Cannot remove last admin");

        return _createProposal(ProposalType.RemoveAdmin, targetAddress);
    }

    /**
     * @dev Create a proposal to add a member
     * @param targetAddress Address to add as member
     * @return proposalId ID of the created proposal
     */
    function proposeAddMember(address targetAddress) public onlyMember returns (uint256) {
        require(targetAddress != address(0), "Invalid target address");
        require(!members[targetAddress].isMember, "Already a member");

        return _createProposal(ProposalType.AddMember, targetAddress);
    }

    /**
     * @dev Create a proposal to remove a member
     * @param targetAddress Address to remove as member
     * @return proposalId ID of the created proposal
     */
    function proposeRemoveMember(address targetAddress) public onlyMember returns (uint256) {
        require(targetAddress != address(0), "Invalid target address");
        require(members[targetAddress].isMember, "Not a member");
        require(targetAddress != owner, "Cannot remove owner");

        return _createProposal(ProposalType.RemoveMember, targetAddress);
    }

    /**
     * @dev Internal function to create a proposal
     * @param proposalType Type of proposal
     * @param targetAddress Target address for the proposal
     * @return proposalId ID of the created proposal
     */
    function _createProposal(ProposalType proposalType, address targetAddress) 
        private 
        returns (uint256) 
    {
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
        newProposal.expiryTime = block.timestamp + votingPeriod;
        newProposal.status = ProposalStatus.Active;
        newProposal.executed = false;

        allProposalIds.push(proposalId);
        members[msg.sender].proposalsCreated++;

        emit ProposalCreated(proposalId, proposalType, targetAddress, msg.sender);

        return proposalId;
    }

    /**
     * @dev Vote on a proposal
     * @param proposalId Proposal ID
     * @param voteFor true to vote for, false to vote against
     */
    function vote(uint256 proposalId, bool voteFor) 
        public 
        onlyMember
        proposalExists(proposalId)
        proposalActive(proposalId)
    {
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;
        voteChoice[proposalId][msg.sender] = voteFor;

        Proposal storage proposal = proposals[proposalId];
        
        if (voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        members[msg.sender].votesSubmitted++;

        emit VoteCast(proposalId, msg.sender, voteFor);
    }

    /**
     * @dev Execute a proposal after voting period
     * @param proposalId Proposal ID
     */
    function executeProposal(uint256 proposalId) 
        public 
        proposalExists(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp >= proposal.expiryTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = (memberCount * quorumPercentage) / 100;
        
        // Check quorum
        if (totalVotes < requiredQuorum) {
            proposal.status = ProposalStatus.Rejected;
            proposal.executed = true;
            emit ProposalExecuted(proposalId, ProposalStatus.Rejected);
            return;
        }

        // Check approval
        uint256 requiredApproval = (totalVotes * approvalPercentage) / 100;
        
        if (proposal.votesFor >= requiredApproval) {
            proposal.status = ProposalStatus.Passed;
            
            // Execute the action
            if (proposal.proposalType == ProposalType.AddAdmin) {
                _addAdmin(proposal.targetAddress);
            } else if (proposal.proposalType == ProposalType.RemoveAdmin) {
                _removeAdmin(proposal.targetAddress);
            } else if (proposal.proposalType == ProposalType.AddMember) {
                _addMember(proposal.targetAddress);
            } else if (proposal.proposalType == ProposalType.RemoveMember) {
                _removeMember(proposal.targetAddress);
            }
        } else {
            proposal.status = ProposalStatus.Rejected;
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.status);
    }

    /**
     * @dev Internal function to add admin
     * @param admin Admin address
     */
    function _addAdmin(address admin) private {
        if (!admins[admin]) {
            admins[admin] = true;
            members[admin].isAdmin = true;
            adminList.push(admin);
            adminCount++;
            emit AdminAdded(admin);
        }
    }

    /**
     * @dev Internal function to remove admin
     * @param admin Admin address
     */
    function _removeAdmin(address admin) private {
        if (admins[admin] && admin != owner && adminCount > 1) {
            admins[admin] = false;
            members[admin].isAdmin = false;
            adminCount--;
            emit AdminRemoved(admin);
        }
    }

    /**
     * @dev Internal function to add member
     * @param member Member address
     */
    function _addMember(address member) private {
        if (!members[member].isMember) {
            members[member] = MemberInfo({
                isMember: true,
                isAdmin: false,
                joinedAt: block.timestamp,
                proposalsCreated: 0,
                votesSubmitted: 0
            });
            memberList.push(member);
            memberCount++;
            emit MemberAdded(member);
        }
    }

    /**
     * @dev Internal function to remove member
     * @param member Member address
     */
    function _removeMember(address member) private {
        if (members[member].isMember && member != owner) {
            // If member is admin, remove admin status first
            if (admins[member]) {
                _removeAdmin(member);
            }
            
            members[member].isMember = false;
            memberCount--;
            emit MemberRemoved(member);
        }
    }

    /**
     * @dev Owner can directly add a member
     * @param member Member address
     */
    function addMemberDirectly(address member) public onlyOwner {
        require(member != address(0), "Invalid member address");
        require(!members[member].isMember, "Already a member");
        
        _addMember(member);
    }

    /**
     * @dev Owner can directly add an admin
     * @param admin Admin address
     */
    function addAdminDirectly(address admin) public onlyOwner {
        require(admin != address(0), "Invalid admin address");
        
        if (!members[admin].isMember) {
            _addMember(admin);
        }
        
        _addAdmin(admin);
    }

    /**
     * @dev Get proposal details
     * @param proposalId Proposal ID
     * @return Proposal details
     */
    function getProposal(uint256 proposalId) 
        public 
        view 
        proposalExists(proposalId)
        returns (Proposal memory) 
    {
        return proposals[proposalId];
    }

    /**
     * @dev Check if address has voted on proposal
     * @param proposalId Proposal ID
     * @param voter Voter address
     * @return true if voted
     */
    function hasAddressVoted(uint256 proposalId, address voter) 
        public 
        view 
        proposalExists(proposalId)
        returns (bool) 
    {
        return hasVoted[proposalId][voter];
    }

    /**
     * @dev Get vote choice
     * @param proposalId Proposal ID
     * @param voter Voter address
     * @return Vote choice (true = for, false = against)
     */
    function getVoteChoice(uint256 proposalId, address voter) 
        public 
        view 
        proposalExists(proposalId)
        returns (bool) 
    {
        require(hasVoted[proposalId][voter], "Voter has not voted");
        return voteChoice[proposalId][voter];
    }

    /**
     * @dev Get all proposals
     * @return Array of all proposals
     */
    function getAllProposals() public view returns (Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](allProposalIds.length);
        
        for (uint256 i = 0; i < allProposalIds.length; i++) {
            allProposals[i] = proposals[allProposalIds[i]];
        }
        
        return allProposals;
    }

    /**
     * @dev Get active proposals
     * @return Array of active proposals
     */
    function getActiveProposals() public view returns (Proposal[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allProposalIds.length; i++) {
            Proposal memory proposal = proposals[allProposalIds[i]];
            if (proposal.status == ProposalStatus.Active && block.timestamp < proposal.expiryTime) {
                count++;
            }
        }

        Proposal[] memory result = new Proposal[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allProposalIds.length; i++) {
            Proposal memory proposal = proposals[allProposalIds[i]];
            if (proposal.status == ProposalStatus.Active && block.timestamp < proposal.expiryTime) {
                result[index] = proposal;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get member information
     * @param member Member address
     * @return MemberInfo details
     */
    function getMemberInfo(address member) public view returns (MemberInfo memory) {
        return members[member];
    }

    /**
     * @dev Check if address is a member
     * @param member Address to check
     * @return true if member
     */
    function isMember(address member) public view returns (bool) {
        return members[member].isMember;
    }

    /**
     * @dev Check if address is an admin
     * @param admin Address to check
     * @return true if admin
     */
    function isAdmin(address admin) public view returns (bool) {
        return admins[admin];
    }

    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getAllMembers() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].isMember) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].isMember) {
                result[index] = memberList[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get all admins
     * @return Array of admin addresses
     */
    function getAllAdmins() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < adminList.length; i++) {
            if (admins[adminList[i]]) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < adminList.length; i++) {
            if (admins[adminList[i]]) {
                result[index] = adminList[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total proposal count
     * @return Total number of proposals
     */
    function getTotalProposalCount() public view returns (uint256) {
        return proposalCounter;
    }

    /**
     * @dev Get member count
     * @return Total number of members
     */
    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    /**
     * @dev Get admin count
     * @return Total number of admins
     */
    function getAdminCount() public view returns (uint256) {
        return adminCount;
    }

    /**
     * @dev Update voting settings
     * @param newVotingPeriod New voting period
     * @param newQuorumPercentage New quorum percentage
     * @param newApprovalPercentage New approval percentage
     */
    function updateSettings(
        uint256 newVotingPeriod,
        uint256 newQuorumPercentage,
        uint256 newApprovalPercentage
    ) public onlyOwner {
        require(newQuorumPercentage > 0 && newQuorumPercentage <= 100, "Invalid quorum percentage");
        require(newApprovalPercentage > 0 && newApprovalPercentage <= 100, "Invalid approval percentage");

        votingPeriod = newVotingPeriod;
        quorumPercentage = newQuorumPercentage;
        approvalPercentage = newApprovalPercentage;

        emit SettingsUpdated(newVotingPeriod, newQuorumPercentage, newApprovalPercentage);
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        
        // Ensure new owner is a member and admin
        if (!members[newOwner].isMember) {
            _addMember(newOwner);
        }
        if (!admins[newOwner]) {
            _addAdmin(newOwner);
        }

        owner = newOwner;
    }
}
