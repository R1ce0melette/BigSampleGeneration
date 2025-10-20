// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CommunityProposals
 * @dev Contract that manages community proposals where members can submit and vote on project ideas
 */
contract CommunityProposals {
    // Proposal status enum
    enum ProposalStatus {
        Pending,
        Active,
        Approved,
        Rejected,
        Executed,
        Cancelled
    }

    // Vote type enum
    enum VoteType {
        For,
        Against,
        Abstain
    }

    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 totalVotes;
        ProposalStatus status;
        uint256 createdAt;
        uint256 executedAt;
    }

    // Vote structure
    struct Vote {
        address voter;
        uint256 proposalId;
        VoteType voteType;
        uint256 timestamp;
    }

    // Member statistics
    struct MemberStats {
        uint256 proposalsSubmitted;
        uint256 proposalsApproved;
        uint256 proposalsRejected;
        uint256 totalVotesCast;
        bool isMember;
        uint256 joinedAt;
    }

    // State variables
    address public owner;
    uint256 private proposalCounter;
    uint256 public votingDuration;
    uint256 public quorumPercentage; // in basis points (5000 = 50%)
    uint256 public approvalThreshold; // in basis points (5000 = 50%)

    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => mapping(address => bool)) private hasVoted;
    mapping(uint256 => mapping(address => VoteType)) private votes;
    mapping(uint256 => Vote[]) private proposalVotes;
    mapping(address => uint256[]) private memberProposals;
    mapping(address => MemberStats) private memberStats;
    mapping(address => bool) public isMember;

    address[] private members;
    uint256[] private allProposalIds;

    // Events
    event MemberAdded(address indexed member, uint256 timestamp);
    event MemberRemoved(address indexed member, uint256 timestamp);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title);
    event ProposalActivated(uint256 indexed proposalId);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType);
    event ProposalApproved(uint256 indexed proposalId, uint256 forVotes, uint256 againstVotes);
    event ProposalRejected(uint256 indexed proposalId, uint256 forVotes, uint256 againstVotes);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);
    event VotingParametersUpdated(uint256 votingDuration, uint256 quorumPercentage, uint256 approvalThreshold);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCounter, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 proposalId) {
        require(proposals[proposalId].status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp < proposals[proposalId].votingEndTime, "Voting period has ended");
        _;
    }

    modifier hasNotVoted(uint256 proposalId) {
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");
        _;
    }

    constructor(uint256 _votingDuration, uint256 _quorumPercentage, uint256 _approvalThreshold) {
        owner = msg.sender;
        proposalCounter = 0;
        votingDuration = _votingDuration;
        quorumPercentage = _quorumPercentage;
        approvalThreshold = _approvalThreshold;
        
        // Add owner as first member
        isMember[owner] = true;
        members.push(owner);
        memberStats[owner].isMember = true;
        memberStats[owner].joinedAt = block.timestamp;
    }

    /**
     * @dev Add a new member
     * @param member Member address
     */
    function addMember(address member) public onlyOwner {
        require(member != address(0), "Invalid member address");
        require(!isMember[member], "Already a member");

        isMember[member] = true;
        members.push(member);
        
        memberStats[member].isMember = true;
        memberStats[member].joinedAt = block.timestamp;

        emit MemberAdded(member, block.timestamp);
    }

    /**
     * @dev Remove a member
     * @param member Member address
     */
    function removeMember(address member) public onlyOwner {
        require(member != owner, "Cannot remove owner");
        require(isMember[member], "Not a member");

        isMember[member] = false;
        memberStats[member].isMember = false;

        emit MemberRemoved(member, block.timestamp);
    }

    /**
     * @dev Submit a new proposal
     * @param title Proposal title
     * @param description Proposal description
     * @return proposalId ID of the created proposal
     */
    function submitProposal(string memory title, string memory description) 
        public 
        onlyMember 
        returns (uint256) 
    {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");

        proposalCounter++;
        uint256 proposalId = proposalCounter;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.votingStartTime = 0;
        newProposal.votingEndTime = 0;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.totalVotes = 0;
        newProposal.status = ProposalStatus.Pending;
        newProposal.createdAt = block.timestamp;
        newProposal.executedAt = 0;

        memberProposals[msg.sender].push(proposalId);
        allProposalIds.push(proposalId);

        // Update statistics
        memberStats[msg.sender].proposalsSubmitted++;

        emit ProposalSubmitted(proposalId, msg.sender, title);

        return proposalId;
    }

    /**
     * @dev Activate a proposal for voting
     * @param proposalId Proposal ID
     */
    function activateProposal(uint256 proposalId) 
        public 
        onlyOwner 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");

        proposal.status = ProposalStatus.Active;
        proposal.votingStartTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + votingDuration;

        emit ProposalActivated(proposalId);
    }

    /**
     * @dev Cast a vote on a proposal
     * @param proposalId Proposal ID
     * @param voteType Vote type (0: For, 1: Against, 2: Abstain)
     */
    function castVote(uint256 proposalId, VoteType voteType) 
        public 
        onlyMember 
        proposalExists(proposalId) 
        proposalActive(proposalId) 
        hasNotVoted(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];

        hasVoted[proposalId][msg.sender] = true;
        votes[proposalId][msg.sender] = voteType;

        Vote memory newVote = Vote({
            voter: msg.sender,
            proposalId: proposalId,
            voteType: voteType,
            timestamp: block.timestamp
        });

        proposalVotes[proposalId].push(newVote);

        if (voteType == VoteType.For) {
            proposal.forVotes++;
        } else if (voteType == VoteType.Against) {
            proposal.againstVotes++;
        } else {
            proposal.abstainVotes++;
        }

        proposal.totalVotes++;

        // Update statistics
        memberStats[msg.sender].totalVotesCast++;

        emit VoteCast(proposalId, msg.sender, voteType);
    }

    /**
     * @dev Finalize voting and determine outcome
     * @param proposalId Proposal ID
     */
    function finalizeProposal(uint256 proposalId) 
        public 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended");

        uint256 totalMembers = members.length;
        uint256 quorumRequired = (totalMembers * quorumPercentage) / 10000;
        uint256 votesNeededForApproval = (proposal.totalVotes * approvalThreshold) / 10000;

        // Check if quorum is met
        if (proposal.totalVotes < quorumRequired) {
            proposal.status = ProposalStatus.Rejected;
            memberStats[proposal.proposer].proposalsRejected++;
            emit ProposalRejected(proposalId, proposal.forVotes, proposal.againstVotes);
            return;
        }

        // Check if approval threshold is met
        if (proposal.forVotes >= votesNeededForApproval) {
            proposal.status = ProposalStatus.Approved;
            memberStats[proposal.proposer].proposalsApproved++;
            emit ProposalApproved(proposalId, proposal.forVotes, proposal.againstVotes);
        } else {
            proposal.status = ProposalStatus.Rejected;
            memberStats[proposal.proposer].proposalsRejected++;
            emit ProposalRejected(proposalId, proposal.forVotes, proposal.againstVotes);
        }
    }

    /**
     * @dev Execute an approved proposal
     * @param proposalId Proposal ID
     */
    function executeProposal(uint256 proposalId) 
        public 
        onlyOwner 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Approved, "Proposal is not approved");

        proposal.status = ProposalStatus.Executed;
        proposal.executedAt = block.timestamp;

        emit ProposalExecuted(proposalId, msg.sender);
    }

    /**
     * @dev Cancel a proposal
     * @param proposalId Proposal ID
     */
    function cancelProposal(uint256 proposalId) 
        public 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer || msg.sender == owner,
            "Only proposer or owner can cancel"
        );
        require(
            proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active,
            "Cannot cancel proposal in current status"
        );

        proposal.status = ProposalStatus.Cancelled;

        emit ProposalCancelled(proposalId, msg.sender);
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
     * @dev Get proposal votes
     * @param proposalId Proposal ID
     * @return Array of votes
     */
    function getProposalVotes(uint256 proposalId) 
        public 
        view 
        proposalExists(proposalId) 
        returns (Vote[] memory) 
    {
        return proposalVotes[proposalId];
    }

    /**
     * @dev Check if user has voted on proposal
     * @param proposalId Proposal ID
     * @param voter Voter address
     * @return true if voted
     */
    function hasUserVoted(uint256 proposalId, address voter) 
        public 
        view 
        proposalExists(proposalId) 
        returns (bool) 
    {
        return hasVoted[proposalId][voter];
    }

    /**
     * @dev Get user's vote on proposal
     * @param proposalId Proposal ID
     * @param voter Voter address
     * @return Vote type
     */
    function getUserVote(uint256 proposalId, address voter) 
        public 
        view 
        proposalExists(proposalId) 
        returns (VoteType) 
    {
        require(hasVoted[proposalId][voter], "User has not voted");
        return votes[proposalId][voter];
    }

    /**
     * @dev Get member proposals
     * @param member Member address
     * @return Array of proposal IDs
     */
    function getMemberProposals(address member) public view returns (uint256[] memory) {
        return memberProposals[member];
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
     * @dev Get proposals by status
     * @param status Proposal status
     * @return Array of proposals
     */
    function getProposalsByStatus(ProposalStatus status) public view returns (Proposal[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allProposalIds.length; i++) {
            if (proposals[allProposalIds[i]].status == status) {
                count++;
            }
        }

        Proposal[] memory result = new Proposal[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allProposalIds.length; i++) {
            Proposal memory proposal = proposals[allProposalIds[i]];
            if (proposal.status == status) {
                result[index] = proposal;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get active proposals
     * @return Array of active proposals
     */
    function getActiveProposals() public view returns (Proposal[] memory) {
        return getProposalsByStatus(ProposalStatus.Active);
    }

    /**
     * @dev Get pending proposals
     * @return Array of pending proposals
     */
    function getPendingProposals() public view returns (Proposal[] memory) {
        return getProposalsByStatus(ProposalStatus.Pending);
    }

    /**
     * @dev Get approved proposals
     * @return Array of approved proposals
     */
    function getApprovedProposals() public view returns (Proposal[] memory) {
        return getProposalsByStatus(ProposalStatus.Approved);
    }

    /**
     * @dev Get rejected proposals
     * @return Array of rejected proposals
     */
    function getRejectedProposals() public view returns (Proposal[] memory) {
        return getProposalsByStatus(ProposalStatus.Rejected);
    }

    /**
     * @dev Get executed proposals
     * @return Array of executed proposals
     */
    function getExecutedProposals() public view returns (Proposal[] memory) {
        return getProposalsByStatus(ProposalStatus.Executed);
    }

    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getAllMembers() public view returns (address[] memory) {
        return members;
    }

    /**
     * @dev Get active members
     * @return Array of active member addresses
     */
    function getActiveMembers() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                result[index] = members[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get member statistics
     * @param member Member address
     * @return MemberStats details
     */
    function getMemberStats(address member) public view returns (MemberStats memory) {
        return memberStats[member];
    }

    /**
     * @dev Get total proposal count
     * @return Total number of proposals
     */
    function getTotalProposalCount() public view returns (uint256) {
        return proposalCounter;
    }

    /**
     * @dev Get total member count
     * @return Total number of members
     */
    function getTotalMemberCount() public view returns (uint256) {
        return members.length;
    }

    /**
     * @dev Get active member count
     * @return Number of active members
     */
    function getActiveMemberCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Check if proposal voting has ended
     * @param proposalId Proposal ID
     * @return true if ended
     */
    function hasVotingEnded(uint256 proposalId) 
        public 
        view 
        proposalExists(proposalId) 
        returns (bool) 
    {
        return block.timestamp >= proposals[proposalId].votingEndTime;
    }

    /**
     * @dev Get time remaining for voting
     * @param proposalId Proposal ID
     * @return Seconds remaining (0 if ended)
     */
    function getVotingTimeRemaining(uint256 proposalId) 
        public 
        view 
        proposalExists(proposalId) 
        returns (uint256) 
    {
        if (block.timestamp >= proposals[proposalId].votingEndTime) {
            return 0;
        }
        return proposals[proposalId].votingEndTime - block.timestamp;
    }

    /**
     * @dev Calculate vote percentages
     * @param proposalId Proposal ID
     * @return forPercentage, againstPercentage, abstainPercentage
     */
    function getVotePercentages(uint256 proposalId) 
        public 
        view 
        proposalExists(proposalId) 
        returns (uint256, uint256, uint256) 
    {
        Proposal memory proposal = proposals[proposalId];
        
        if (proposal.totalVotes == 0) {
            return (0, 0, 0);
        }

        uint256 forPercentage = (proposal.forVotes * 100) / proposal.totalVotes;
        uint256 againstPercentage = (proposal.againstVotes * 100) / proposal.totalVotes;
        uint256 abstainPercentage = (proposal.abstainVotes * 100) / proposal.totalVotes;

        return (forPercentage, againstPercentage, abstainPercentage);
    }

    /**
     * @dev Update voting parameters
     * @param _votingDuration New voting duration
     * @param _quorumPercentage New quorum percentage
     * @param _approvalThreshold New approval threshold
     */
    function updateVotingParameters(
        uint256 _votingDuration,
        uint256 _quorumPercentage,
        uint256 _approvalThreshold
    ) public onlyOwner {
        require(_votingDuration > 0, "Voting duration must be greater than 0");
        require(_quorumPercentage <= 10000, "Quorum percentage cannot exceed 100%");
        require(_approvalThreshold <= 10000, "Approval threshold cannot exceed 100%");

        votingDuration = _votingDuration;
        quorumPercentage = _quorumPercentage;
        approvalThreshold = _approvalThreshold;

        emit VotingParametersUpdated(_votingDuration, _quorumPercentage, _approvalThreshold);
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        
        // Add new owner as member if not already
        if (!isMember[newOwner]) {
            isMember[newOwner] = true;
            members.push(newOwner);
            memberStats[newOwner].isMember = true;
            memberStats[newOwner].joinedAt = block.timestamp;
        }
        
        owner = newOwner;
    }
}
