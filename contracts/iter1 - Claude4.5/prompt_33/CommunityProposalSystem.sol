// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CommunityProposalSystem
 * @dev A contract that manages community proposals where members can submit and vote on project ideas
 */
contract CommunityProposalSystem {
    enum ProposalStatus {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        EXECUTED,
        CANCELLED
    }
    
    enum VoteType {
        FOR,
        AGAINST,
        ABSTAIN
    }
    
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 createdAt;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        ProposalStatus status;
        uint256 quorumRequired;
        bool executed;
    }
    
    struct Vote {
        address voter;
        VoteType voteType;
        uint256 timestamp;
    }
    
    uint256 private proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Vote)) public votes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => Vote[]) private proposalVotes;
    mapping(address => uint256[]) private memberProposals;
    mapping(address => uint256[]) private memberVotedProposals;
    
    mapping(address => bool) public isMember;
    address[] private members;
    
    address public owner;
    uint256 public defaultVotingPeriod;
    uint256 public defaultQuorumPercentage;
    uint256 public constant PERCENTAGE_DENOMINATOR = 100;
    
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 votingEndTime
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        VoteType voteType,
        uint256 timestamp
    );
    
    event ProposalStatusChanged(
        uint256 indexed proposalId,
        ProposalStatus newStatus
    );
    
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCounter, "Proposal does not exist");
        _;
    }
    
    constructor(uint256 _votingPeriod, uint256 _quorumPercentage) {
        owner = msg.sender;
        isMember[msg.sender] = true;
        members.push(msg.sender);
        
        defaultVotingPeriod = _votingPeriod;
        defaultQuorumPercentage = _quorumPercentage;
        
        emit MemberAdded(msg.sender);
    }
    
    /**
     * @dev Add a new member to the community
     * @param newMember The address of the new member
     */
    function addMember(address newMember) external onlyOwner {
        require(newMember != address(0), "Invalid address");
        require(!isMember[newMember], "Already a member");
        
        isMember[newMember] = true;
        members.push(newMember);
        
        emit MemberAdded(newMember);
    }
    
    /**
     * @dev Remove a member from the community
     * @param member The address of the member to remove
     */
    function removeMember(address member) external onlyOwner {
        require(member != owner, "Cannot remove owner");
        require(isMember[member], "Not a member");
        
        isMember[member] = false;
        
        emit MemberRemoved(member);
    }
    
    /**
     * @dev Create a new proposal
     * @param title The proposal title
     * @param description The proposal description
     * @return proposalId The ID of the created proposal
     */
    function createProposal(
        string memory title,
        string memory description
    ) external onlyMember returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        
        proposalCounter++;
        uint256 proposalId = proposalCounter;
        
        uint256 votingStartTime = block.timestamp;
        uint256 votingEndTime = block.timestamp + defaultVotingPeriod;
        uint256 quorumRequired = (members.length * defaultQuorumPercentage) / PERCENTAGE_DENOMINATOR;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: title,
            description: description,
            createdAt: block.timestamp,
            votingStartTime: votingStartTime,
            votingEndTime: votingEndTime,
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            status: ProposalStatus.ACTIVE,
            quorumRequired: quorumRequired,
            executed: false
        });
        
        memberProposals[msg.sender].push(proposalId);
        
        emit ProposalCreated(proposalId, msg.sender, title, votingEndTime);
        
        return proposalId;
    }
    
    /**
     * @dev Vote on a proposal
     * @param proposalId The ID of the proposal
     * @param voteType The type of vote (FOR, AGAINST, ABSTAIN)
     */
    function vote(uint256 proposalId, VoteType voteType) 
        external 
        onlyMember 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not active");
        require(block.timestamp >= proposal.votingStartTime, "Voting not started");
        require(block.timestamp < proposal.votingEndTime, "Voting has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        hasVoted[proposalId][msg.sender] = true;
        
        Vote memory newVote = Vote({
            voter: msg.sender,
            voteType: voteType,
            timestamp: block.timestamp
        });
        
        votes[proposalId][msg.sender] = newVote;
        proposalVotes[proposalId].push(newVote);
        memberVotedProposals[msg.sender].push(proposalId);
        
        // Update vote counts
        if (voteType == VoteType.FOR) {
            proposal.votesFor++;
        } else if (voteType == VoteType.AGAINST) {
            proposal.votesAgainst++;
        } else {
            proposal.votesAbstain++;
        }
        
        emit VoteCast(proposalId, msg.sender, voteType, block.timestamp);
    }
    
    /**
     * @dev Change vote on a proposal (before voting ends)
     * @param proposalId The ID of the proposal
     * @param newVoteType The new vote type
     */
    function changeVote(uint256 proposalId, VoteType newVoteType) 
        external 
        onlyMember 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not active");
        require(block.timestamp < proposal.votingEndTime, "Voting has ended");
        require(hasVoted[proposalId][msg.sender], "Haven't voted yet");
        
        Vote storage existingVote = votes[proposalId][msg.sender];
        VoteType oldVoteType = existingVote.voteType;
        
        require(oldVoteType != newVoteType, "Vote is already this type");
        
        // Reverse old vote
        if (oldVoteType == VoteType.FOR) {
            proposal.votesFor--;
        } else if (oldVoteType == VoteType.AGAINST) {
            proposal.votesAgainst--;
        } else {
            proposal.votesAbstain--;
        }
        
        // Apply new vote
        if (newVoteType == VoteType.FOR) {
            proposal.votesFor++;
        } else if (newVoteType == VoteType.AGAINST) {
            proposal.votesAgainst++;
        } else {
            proposal.votesAbstain++;
        }
        
        existingVote.voteType = newVoteType;
        existingVote.timestamp = block.timestamp;
        
        emit VoteCast(proposalId, msg.sender, newVoteType, block.timestamp);
    }
    
    /**
     * @dev Finalize a proposal after voting period ends
     * @param proposalId The ID of the proposal
     */
    function finalizeProposal(uint256 proposalId) 
        external 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not active");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        
        // Check if quorum is met
        if (totalVotes < proposal.quorumRequired) {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalStatusChanged(proposalId, ProposalStatus.REJECTED);
            return;
        }
        
        // Determine if proposal passed
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.PASSED;
            emit ProposalStatusChanged(proposalId, ProposalStatus.PASSED);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalStatusChanged(proposalId, ProposalStatus.REJECTED);
        }
    }
    
    /**
     * @dev Execute a passed proposal
     * @param proposalId The ID of the proposal
     */
    function executeProposal(uint256 proposalId) 
        external 
        onlyOwner 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.PASSED, "Proposal not passed");
        require(!proposal.executed, "Proposal already executed");
        
        proposal.executed = true;
        proposal.status = ProposalStatus.EXECUTED;
        
        emit ProposalExecuted(proposalId, msg.sender);
        emit ProposalStatusChanged(proposalId, ProposalStatus.EXECUTED);
    }
    
    /**
     * @dev Cancel a proposal (only by proposer or owner, before voting ends)
     * @param proposalId The ID of the proposal
     */
    function cancelProposal(uint256 proposalId) 
        external 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        
        require(
            msg.sender == proposal.proposer || msg.sender == owner,
            "Only proposer or owner can cancel"
        );
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not active");
        
        proposal.status = ProposalStatus.CANCELLED;
        
        emit ProposalStatusChanged(proposalId, ProposalStatus.CANCELLED);
    }
    
    /**
     * @dev Get proposal details
     * @param proposalId The ID of the proposal
     * @return id Proposal ID
     * @return proposer Proposer address
     * @return title Proposal title
     * @return description Proposal description
     * @return createdAt Creation timestamp
     * @return votingStartTime Voting start time
     * @return votingEndTime Voting end time
     * @return votesFor Votes in favor
     * @return votesAgainst Votes against
     * @return votesAbstain Abstain votes
     * @return status Proposal status
     * @return quorumRequired Quorum required
     * @return executed Whether executed
     */
    function getProposalDetails(uint256 proposalId) 
        external 
        view 
        proposalExists(proposalId) 
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory description,
            uint256 createdAt,
            uint256 votingStartTime,
            uint256 votingEndTime,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 votesAbstain,
            ProposalStatus status,
            uint256 quorumRequired,
            bool executed
        ) 
    {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.createdAt,
            proposal.votingStartTime,
            proposal.votingEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.votesAbstain,
            proposal.status,
            proposal.quorumRequired,
            proposal.executed
        );
    }
    
    /**
     * @dev Get vote details for a proposal and voter
     * @param proposalId The ID of the proposal
     * @param voter The voter's address
     * @return voteType Type of vote
     * @return timestamp When the vote was cast
     * @return hasVotedFlag Whether the user has voted
     */
    function getVote(uint256 proposalId, address voter) 
        external 
        view 
        proposalExists(proposalId) 
        returns (
            VoteType voteType,
            uint256 timestamp,
            bool hasVotedFlag
        ) 
    {
        if (!hasVoted[proposalId][voter]) {
            return (VoteType.FOR, 0, false);
        }
        
        Vote memory userVote = votes[proposalId][voter];
        return (userVote.voteType, userVote.timestamp, true);
    }
    
    /**
     * @dev Get all votes for a proposal
     * @param proposalId The ID of the proposal
     * @return Array of votes
     */
    function getProposalVotes(uint256 proposalId) 
        external 
        view 
        proposalExists(proposalId) 
        returns (Vote[] memory) 
    {
        return proposalVotes[proposalId];
    }
    
    /**
     * @dev Get proposals created by a member
     * @param member The member's address
     * @return Array of proposal IDs
     */
    function getProposalsByMember(address member) external view returns (uint256[] memory) {
        return memberProposals[member];
    }
    
    /**
     * @dev Get proposals voted on by a member
     * @param member The member's address
     * @return Array of proposal IDs
     */
    function getVotedProposalsByMember(address member) external view returns (uint256[] memory) {
        return memberVotedProposals[member];
    }
    
    /**
     * @dev Get all active proposals
     * @return Array of active proposal IDs
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active proposals
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE) {
                activeCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeProposals = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE) {
                activeProposals[index] = i;
                index++;
            }
        }
        
        return activeProposals;
    }
    
    /**
     * @dev Get all passed proposals
     * @return Array of passed proposal IDs
     */
    function getPassedProposals() external view returns (uint256[] memory) {
        uint256 passedCount = 0;
        
        // Count passed proposals
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.PASSED) {
                passedCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory passedProposals = new uint256[](passedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.PASSED) {
                passedProposals[index] = i;
                index++;
            }
        }
        
        return passedProposals;
    }
    
    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    /**
     * @dev Get active members (those who are still members)
     * @return Array of active member addresses
     */
    function getActiveMembers() external view returns (address[] memory) {
        uint256 activeCount = 0;
        
        // Count active members
        for (uint256 i = 0; i < members.length; i++) {
            if (isMember[members[i]]) {
                activeCount++;
            }
        }
        
        // Create array and populate
        address[] memory activeMembers = new address[](activeCount);
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
     * @dev Get total number of proposals
     * @return The total count
     */
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter;
    }
    
    /**
     * @dev Get total number of members
     * @return The total count
     */
    function getTotalMembers() external view returns (uint256) {
        return members.length;
    }
    
    /**
     * @dev Get voting results for a proposal
     * @param proposalId The ID of the proposal
     * @return votesFor Votes in favor
     * @return votesAgainst Votes against
     * @return votesAbstain Abstain votes
     * @return totalVotes Total votes cast
     */
    function getVotingResults(uint256 proposalId) 
        external 
        view 
        proposalExists(proposalId) 
        returns (
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 votesAbstain,
            uint256 totalVotes
        ) 
    {
        Proposal memory proposal = proposals[proposalId];
        uint256 total = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        return (proposal.votesFor, proposal.votesAgainst, proposal.votesAbstain, total);
    }
    
    /**
     * @dev Check if quorum is met for a proposal
     * @param proposalId The ID of the proposal
     * @return Whether quorum is met
     */
    function isQuorumMet(uint256 proposalId) 
        external 
        view 
        proposalExists(proposalId) 
        returns (bool) 
    {
        Proposal memory proposal = proposals[proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        return totalVotes >= proposal.quorumRequired;
    }
    
    /**
     * @dev Get time remaining for voting
     * @param proposalId The ID of the proposal
     * @return Time remaining in seconds (0 if ended)
     */
    function getVotingTimeRemaining(uint256 proposalId) 
        external 
        view 
        proposalExists(proposalId) 
        returns (uint256) 
    {
        Proposal memory proposal = proposals[proposalId];
        
        if (block.timestamp >= proposal.votingEndTime) {
            return 0;
        }
        
        return proposal.votingEndTime - block.timestamp;
    }
}
