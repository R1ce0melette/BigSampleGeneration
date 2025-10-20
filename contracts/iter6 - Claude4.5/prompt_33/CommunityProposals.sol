// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CommunityProposals
 * @dev A contract that manages community proposals where members can submit and vote on project ideas
 */
contract CommunityProposals {
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 votingDeadline;
        bool isActive;
        bool isExecuted;
        ProposalStatus status;
    }
    
    enum ProposalStatus {
        Pending,
        Active,
        Passed,
        Rejected,
        Executed
    }
    
    struct Member {
        bool isMember;
        uint256 joinedAt;
        uint256 proposalsSubmitted;
        uint256 votesParticipated;
    }
    
    address public owner;
    uint256 public proposalCount;
    uint256 public memberCount;
    uint256 public votingPeriod = 7 days;
    uint256 public quorumPercentage = 50; // 50% of members must vote
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => bool)) public voteChoice; // true = for, false = against
    mapping(address => uint256[]) public memberProposals;
    
    address[] public memberAddresses;
    
    // Events
    event MemberJoined(address indexed member, uint256 timestamp);
    event MemberRemoved(address indexed member, uint256 timestamp);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteFor, uint256 timestamp);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus status);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event VotingPeriodUpdated(uint256 newPeriod);
    event QuorumUpdated(uint256 newQuorum);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender].isMember, "Only members can perform this action");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCount, "Proposal does not exist");
        _;
    }
    
    modifier proposalActive(uint256 proposalId) {
        require(proposals[proposalId].isActive, "Proposal is not active");
        require(block.timestamp < proposals[proposalId].votingDeadline, "Voting period has ended");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        members[msg.sender].isMember = true;
        members[msg.sender].joinedAt = block.timestamp;
        memberAddresses.push(msg.sender);
        memberCount = 1;
    }
    
    /**
     * @dev Join the community as a member
     */
    function joinCommunity() external {
        require(!members[msg.sender].isMember, "Already a member");
        
        members[msg.sender] = Member({
            isMember: true,
            joinedAt: block.timestamp,
            proposalsSubmitted: 0,
            votesParticipated: 0
        });
        
        memberAddresses.push(msg.sender);
        memberCount++;
        
        emit MemberJoined(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Remove a member (owner only)
     * @param member The member address to remove
     */
    function removeMember(address member) external onlyOwner {
        require(members[member].isMember, "Not a member");
        require(member != owner, "Cannot remove owner");
        
        members[member].isMember = false;
        memberCount--;
        
        emit MemberRemoved(member, block.timestamp);
    }
    
    /**
     * @dev Submit a new proposal
     * @param title Proposal title
     * @param description Proposal description
     */
    function submitProposal(string memory title, string memory description) external onlyMember returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        uint256 deadline = block.timestamp + votingPeriod;
        
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: title,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            votingDeadline: deadline,
            isActive: true,
            isExecuted: false,
            status: ProposalStatus.Active
        });
        
        members[msg.sender].proposalsSubmitted++;
        memberProposals[msg.sender].push(proposalId);
        
        emit ProposalSubmitted(proposalId, msg.sender, title, deadline);
        emit ProposalStatusChanged(proposalId, ProposalStatus.Active);
        
        return proposalId;
    }
    
    /**
     * @dev Vote on a proposal
     * @param proposalId The proposal ID
     * @param voteFor True to vote for, false to vote against
     */
    function vote(uint256 proposalId, bool voteFor) external onlyMember proposalExists(proposalId) proposalActive(proposalId) {
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");
        
        hasVoted[proposalId][msg.sender] = true;
        voteChoice[proposalId][msg.sender] = voteFor;
        
        if (voteFor) {
            proposals[proposalId].votesFor++;
        } else {
            proposals[proposalId].votesAgainst++;
        }
        
        members[msg.sender].votesParticipated++;
        
        emit VoteCast(proposalId, msg.sender, voteFor, block.timestamp);
    }
    
    /**
     * @dev Finalize a proposal after voting period
     * @param proposalId The proposal ID
     */
    function finalizeProposal(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.isActive, "Proposal is not active");
        require(block.timestamp >= proposal.votingDeadline, "Voting period has not ended");
        
        proposal.isActive = false;
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumRequired = (memberCount * quorumPercentage) / 100;
        
        // Check if quorum is met and majority voted for
        if (totalVotes >= quorumRequired && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Passed;
            emit ProposalStatusChanged(proposalId, ProposalStatus.Passed);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalStatusChanged(proposalId, ProposalStatus.Rejected);
        }
    }
    
    /**
     * @dev Mark a proposal as executed
     * @param proposalId The proposal ID
     */
    function executeProposal(uint256 proposalId) external onlyOwner proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.Passed, "Proposal has not passed");
        require(!proposal.isExecuted, "Proposal already executed");
        
        proposal.isExecuted = true;
        proposal.status = ProposalStatus.Executed;
        
        emit ProposalExecuted(proposalId, msg.sender);
        emit ProposalStatusChanged(proposalId, ProposalStatus.Executed);
    }
    
    /**
     * @dev Get proposal details
     * @param proposalId The proposal ID
     * @return proposer Proposer address
     * @return title Proposal title
     * @return description Proposal description
     * @return votesFor Votes in favor
     * @return votesAgainst Votes against
     * @return deadline Voting deadline
     * @return status Proposal status
     * @return isExecuted Execution status
     */
    function getProposal(uint256 proposalId) external view proposalExists(proposalId) returns (
        address proposer,
        string memory title,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 deadline,
        ProposalStatus status,
        bool isExecuted
    ) {
        Proposal memory proposal = proposals[proposalId];
        
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.votingDeadline,
            proposal.status,
            proposal.isExecuted
        );
    }
    
    /**
     * @dev Get proposal vote count
     * @param proposalId The proposal ID
     * @return votesFor Votes in favor
     * @return votesAgainst Votes against
     * @return totalVotes Total votes
     */
    function getVoteCount(uint256 proposalId) external view proposalExists(proposalId) returns (
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 totalVotes
    ) {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.votesFor, proposal.votesAgainst, proposal.votesFor + proposal.votesAgainst);
    }
    
    /**
     * @dev Check if user has voted on a proposal
     * @param proposalId The proposal ID
     * @param voter The voter address
     * @return voted Whether user has voted
     * @return voteFor Vote choice (only valid if voted is true)
     */
    function getVoteStatus(uint256 proposalId, address voter) external view proposalExists(proposalId) returns (
        bool voted,
        bool voteFor
    ) {
        return (hasVoted[proposalId][voter], voteChoice[proposalId][voter]);
    }
    
    /**
     * @dev Get member information
     * @param member The member address
     * @return isMember Membership status
     * @return joinedAt Join timestamp
     * @return proposalsSubmitted Number of proposals submitted
     * @return votesParticipated Number of votes participated
     */
    function getMemberInfo(address member) external view returns (
        bool isMember,
        uint256 joinedAt,
        uint256 proposalsSubmitted,
        uint256 votesParticipated
    ) {
        Member memory m = members[member];
        return (m.isMember, m.joinedAt, m.proposalsSubmitted, m.votesParticipated);
    }
    
    /**
     * @dev Get all proposals by a member
     * @param member The member address
     * @return Array of proposal IDs
     */
    function getMemberProposals(address member) external view returns (uint256[] memory) {
        return memberProposals[member];
    }
    
    /**
     * @dev Get all active proposals
     * @return Array of proposal IDs
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count active proposals
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].isActive && block.timestamp < proposals[i].votingDeadline) {
                count++;
            }
        }
        
        // Collect proposal IDs
        uint256[] memory activeProposals = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].isActive && block.timestamp < proposals[i].votingDeadline) {
                activeProposals[index] = i;
                index++;
            }
        }
        
        return activeProposals;
    }
    
    /**
     * @dev Get proposals by status
     * @param status The proposal status
     * @return Array of proposal IDs
     */
    function getProposalsByStatus(ProposalStatus status) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count proposals with status
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == status) {
                count++;
            }
        }
        
        // Collect proposal IDs
        uint256[] memory statusProposals = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == status) {
                statusProposals[index] = i;
                index++;
            }
        }
        
        return statusProposals;
    }
    
    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getAllMembers() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count active members
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            if (members[memberAddresses[i]].isMember) {
                count++;
            }
        }
        
        // Collect member addresses
        address[] memory activeMembers = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            if (members[memberAddresses[i]].isMember) {
                activeMembers[index] = memberAddresses[i];
                index++;
            }
        }
        
        return activeMembers;
    }
    
    /**
     * @dev Check if address is a member
     * @param account The address to check
     * @return True if member
     */
    function isMember(address account) external view returns (bool) {
        return members[account].isMember;
    }
    
    /**
     * @dev Set voting period (owner only)
     * @param newPeriod New voting period in seconds
     */
    function setVotingPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Voting period must be greater than 0");
        votingPeriod = newPeriod;
        emit VotingPeriodUpdated(newPeriod);
    }
    
    /**
     * @dev Set quorum percentage (owner only)
     * @param newQuorum New quorum percentage (0-100)
     */
    function setQuorum(uint256 newQuorum) external onlyOwner {
        require(newQuorum > 0 && newQuorum <= 100, "Quorum must be between 1 and 100");
        quorumPercentage = newQuorum;
        emit QuorumUpdated(newQuorum);
    }
    
    /**
     * @dev Get total number of proposals
     * @return Total proposal count
     */
    function getTotalProposals() external view returns (uint256) {
        return proposalCount;
    }
    
    /**
     * @dev Get total number of members
     * @return Total member count
     */
    function getTotalMembers() external view returns (uint256) {
        return memberCount;
    }
    
    /**
     * @dev Transfer ownership
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(members[newOwner].isMember, "New owner must be a member");
        owner = newOwner;
    }
}
