// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CommunityProposals
 * @dev Contract that manages community proposals where members can submit and vote on project ideas
 */
contract CommunityProposals {
    // Proposal status enumeration
    enum ProposalStatus { PENDING, ACTIVE, PASSED, REJECTED, EXECUTED, CANCELLED }

    // Vote type enumeration
    enum VoteType { NONE, FOR, AGAINST, ABSTAIN }

    // Proposal structure
    struct Proposal {
        uint256 proposalId;
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
        bool exists;
    }

    // Vote record structure
    struct VoteRecord {
        address voter;
        uint256 proposalId;
        VoteType voteType;
        uint256 timestamp;
    }

    // Member structure
    struct Member {
        address memberAddress;
        bool isActive;
        uint256 joinedAt;
        uint256 proposalsSubmitted;
        uint256 votescast;
    }

    // State variables
    address public owner;
    uint256 private proposalIdCounter;
    uint256 public votingDuration;
    uint256 public quorumPercentage;
    uint256 public approvalThreshold;
    
    // Mappings
    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => mapping(address => VoteType)) private proposalVotes;
    mapping(uint256 => VoteRecord[]) private proposalVoteRecords;
    mapping(address => bool) private members;
    mapping(address => Member) private memberDetails;
    mapping(address => uint256[]) private memberProposals;
    mapping(address => uint256[]) private memberVotedProposals;
    
    address[] private memberList;
    uint256 public totalMembers;

    // Events
    event MemberAdded(address indexed member, uint256 timestamp);
    event MemberRemoved(address indexed member, uint256 timestamp);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 votingEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 timestamp);
    event VoteChanged(uint256 indexed proposalId, address indexed voter, VoteType oldVote, VoteType newVote);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalExecuted(uint256 indexed proposalId, uint256 timestamp);
    event VotingParametersUpdated(uint256 votingDuration, uint256 quorumPercentage, uint256 approvalThreshold);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].exists, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 proposalId) {
        require(proposals[proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp >= proposals[proposalId].votingStartTime, "Voting has not started");
        require(block.timestamp <= proposals[proposalId].votingEndTime, "Voting has ended");
        _;
    }

    constructor(uint256 _votingDuration, uint256 _quorumPercentage, uint256 _approvalThreshold) {
        require(_quorumPercentage <= 100, "Quorum cannot exceed 100%");
        require(_approvalThreshold <= 100, "Approval threshold cannot exceed 100%");
        
        owner = msg.sender;
        proposalIdCounter = 1;
        votingDuration = _votingDuration;
        quorumPercentage = _quorumPercentage;
        approvalThreshold = _approvalThreshold;
        
        // Add owner as first member
        _addMember(owner);
    }

    /**
     * @dev Add a new member
     * @param member Address to add as member
     */
    function addMember(address member) public onlyOwner {
        require(member != address(0), "Invalid member address");
        require(!members[member], "Already a member");
        
        _addMember(member);
    }

    /**
     * @dev Internal function to add member
     * @param member Address to add
     */
    function _addMember(address member) private {
        members[member] = true;
        memberDetails[member] = Member({
            memberAddress: member,
            isActive: true,
            joinedAt: block.timestamp,
            proposalsSubmitted: 0,
            votescast: 0
        });
        memberList.push(member);
        totalMembers++;
        
        emit MemberAdded(member, block.timestamp);
    }

    /**
     * @dev Remove a member
     * @param member Address to remove
     */
    function removeMember(address member) public onlyOwner {
        require(members[member], "Not a member");
        require(member != owner, "Cannot remove owner");
        
        members[member] = false;
        memberDetails[member].isActive = false;
        totalMembers--;
        
        emit MemberRemoved(member, block.timestamp);
    }

    /**
     * @dev Batch add members
     * @param newMembers Array of addresses to add
     */
    function batchAddMembers(address[] memory newMembers) public onlyOwner {
        for (uint256 i = 0; i < newMembers.length; i++) {
            if (newMembers[i] != address(0) && !members[newMembers[i]]) {
                _addMember(newMembers[i]);
            }
        }
    }

    /**
     * @dev Create a new proposal
     * @param title Proposal title
     * @param description Proposal description
     * @return proposalId ID of created proposal
     */
    function createProposal(
        string memory title,
        string memory description
    ) public onlyMember returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");

        uint256 proposalId = proposalIdCounter;
        proposalIdCounter++;

        uint256 votingStartTime = block.timestamp;
        uint256 votingEndTime = votingStartTime + votingDuration;

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
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
            exists: true
        });

        memberProposals[msg.sender].push(proposalId);
        memberDetails[msg.sender].proposalsSubmitted++;

        emit ProposalCreated(proposalId, msg.sender, title, votingEndTime);

        return proposalId;
    }

    /**
     * @dev Create proposal with custom voting period
     * @param title Proposal title
     * @param description Proposal description
     * @param customVotingDuration Custom voting duration in seconds
     * @return proposalId ID of created proposal
     */
    function createProposalWithCustomDuration(
        string memory title,
        string memory description,
        uint256 customVotingDuration
    ) public onlyMember returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(customVotingDuration > 0, "Duration must be greater than 0");

        uint256 proposalId = proposalIdCounter;
        proposalIdCounter++;

        uint256 votingStartTime = block.timestamp;
        uint256 votingEndTime = votingStartTime + customVotingDuration;

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
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
            exists: true
        });

        memberProposals[msg.sender].push(proposalId);
        memberDetails[msg.sender].proposalsSubmitted++;

        emit ProposalCreated(proposalId, msg.sender, title, votingEndTime);

        return proposalId;
    }

    /**
     * @dev Vote on a proposal
     * @param proposalId Proposal ID to vote on
     * @param voteType Type of vote (FOR, AGAINST, ABSTAIN)
     */
    function vote(uint256 proposalId, VoteType voteType) 
        public 
        onlyMember 
        proposalExists(proposalId) 
        proposalActive(proposalId) 
    {
        require(voteType != VoteType.NONE, "Invalid vote type");
        
        VoteType currentVote = proposalVotes[proposalId][msg.sender];
        require(currentVote == VoteType.NONE, "Already voted, use changeVote instead");

        _castVote(proposalId, voteType);
    }

    /**
     * @dev Change vote on a proposal
     * @param proposalId Proposal ID
     * @param newVoteType New vote type
     */
    function changeVote(uint256 proposalId, VoteType newVoteType) 
        public 
        onlyMember 
        proposalExists(proposalId) 
        proposalActive(proposalId) 
    {
        require(newVoteType != VoteType.NONE, "Invalid vote type");
        
        VoteType currentVote = proposalVotes[proposalId][msg.sender];
        require(currentVote != VoteType.NONE, "No vote to change");
        require(currentVote != newVoteType, "Same vote type");

        // Revert old vote
        Proposal storage proposal = proposals[proposalId];
        if (currentVote == VoteType.FOR) {
            proposal.votesFor--;
        } else if (currentVote == VoteType.AGAINST) {
            proposal.votesAgainst--;
        } else if (currentVote == VoteType.ABSTAIN) {
            proposal.votesAbstain--;
        }

        // Apply new vote
        if (newVoteType == VoteType.FOR) {
            proposal.votesFor++;
        } else if (newVoteType == VoteType.AGAINST) {
            proposal.votesAgainst++;
        } else if (newVoteType == VoteType.ABSTAIN) {
            proposal.votesAbstain++;
        }

        proposalVotes[proposalId][msg.sender] = newVoteType;

        // Record vote change
        proposalVoteRecords[proposalId].push(VoteRecord({
            voter: msg.sender,
            proposalId: proposalId,
            voteType: newVoteType,
            timestamp: block.timestamp
        }));

        emit VoteChanged(proposalId, msg.sender, currentVote, newVoteType);
    }

    /**
     * @dev Internal function to cast vote
     * @param proposalId Proposal ID
     * @param voteType Vote type
     */
    function _castVote(uint256 proposalId, VoteType voteType) private {
        Proposal storage proposal = proposals[proposalId];

        if (voteType == VoteType.FOR) {
            proposal.votesFor++;
        } else if (voteType == VoteType.AGAINST) {
            proposal.votesAgainst++;
        } else if (voteType == VoteType.ABSTAIN) {
            proposal.votesAbstain++;
        }

        proposalVotes[proposalId][msg.sender] = voteType;
        memberVotedProposals[msg.sender].push(proposalId);
        memberDetails[msg.sender].votescast++;

        // Record vote
        proposalVoteRecords[proposalId].push(VoteRecord({
            voter: msg.sender,
            proposalId: proposalId,
            voteType: voteType,
            timestamp: block.timestamp
        }));

        emit VoteCast(proposalId, msg.sender, voteType, block.timestamp);
    }

    /**
     * @dev Finalize a proposal after voting ends
     * @param proposalId Proposal ID to finalize
     */
    function finalizeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp > proposal.votingEndTime, "Voting has not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        uint256 quorumRequired = (totalMembers * quorumPercentage) / 100;

        if (totalVotes < quorumRequired) {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalStatusChanged(proposalId, ProposalStatus.REJECTED);
            return;
        }

        uint256 approvalVotes = (proposal.votesFor * 100) / totalVotes;
        
        if (approvalVotes >= approvalThreshold) {
            proposal.status = ProposalStatus.PASSED;
            emit ProposalStatusChanged(proposalId, ProposalStatus.PASSED);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalStatusChanged(proposalId, ProposalStatus.REJECTED);
        }
    }

    /**
     * @dev Execute a passed proposal
     * @param proposalId Proposal ID to execute
     */
    function executeProposal(uint256 proposalId) public onlyOwner proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.PASSED, "Proposal has not passed");

        proposal.status = ProposalStatus.EXECUTED;
        
        emit ProposalStatusChanged(proposalId, ProposalStatus.EXECUTED);
        emit ProposalExecuted(proposalId, block.timestamp);
    }

    /**
     * @dev Cancel a proposal (only proposer or owner)
     * @param proposalId Proposal ID to cancel
     */
    function cancelProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer || msg.sender == owner,
            "Only proposer or owner can cancel"
        );
        require(
            proposal.status == ProposalStatus.PENDING || proposal.status == ProposalStatus.ACTIVE,
            "Cannot cancel proposal in current status"
        );

        proposal.status = ProposalStatus.CANCELLED;
        emit ProposalStatusChanged(proposalId, ProposalStatus.CANCELLED);
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
        require(_quorumPercentage <= 100, "Quorum cannot exceed 100%");
        require(_approvalThreshold <= 100, "Approval threshold cannot exceed 100%");
        require(_votingDuration > 0, "Duration must be greater than 0");

        votingDuration = _votingDuration;
        quorumPercentage = _quorumPercentage;
        approvalThreshold = _approvalThreshold;

        emit VotingParametersUpdated(_votingDuration, _quorumPercentage, _approvalThreshold);
    }

    // View Functions

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
     * @dev Get proposal vote counts
     * @param proposalId Proposal ID
     * @return votesFor Number of votes for
     * @return votesAgainst Number of votes against
     * @return votesAbstain Number of abstain votes
     * @return totalVotes Total votes cast
     */
    function getProposalVotes(uint256 proposalId) 
        public 
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
        totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        return (proposal.votesFor, proposal.votesAgainst, proposal.votesAbstain, totalVotes);
    }

    /**
     * @dev Get vote type for a member on a proposal
     * @param proposalId Proposal ID
     * @param voter Voter address
     * @return Vote type
     */
    function getVote(uint256 proposalId, address voter) 
        public 
        view 
        proposalExists(proposalId) 
        returns (VoteType) 
    {
        return proposalVotes[proposalId][voter];
    }

    /**
     * @dev Check if address is a member
     * @param account Address to check
     * @return true if member
     */
    function isMember(address account) public view returns (bool) {
        return members[account];
    }

    /**
     * @dev Get member details
     * @param member Member address
     * @return Member details
     */
    function getMemberDetails(address member) public view returns (Member memory) {
        return memberDetails[member];
    }

    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getAllMembers() public view returns (address[] memory) {
        return memberList;
    }

    /**
     * @dev Get active members
     * @return Array of active member addresses
     */
    function getActiveMembers() public view returns (address[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]]) {
                activeCount++;
            }
        }

        address[] memory activeMembers = new address[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]]) {
                activeMembers[index] = memberList[i];
                index++;
            }
        }

        return activeMembers;
    }

    /**
     * @dev Get proposals by member
     * @param member Member address
     * @return Array of proposal IDs
     */
    function getProposalsByMember(address member) public view returns (uint256[] memory) {
        return memberProposals[member];
    }

    /**
     * @dev Get proposals voted by member
     * @param member Member address
     * @return Array of proposal IDs
     */
    function getProposalsVotedByMember(address member) public view returns (uint256[] memory) {
        return memberVotedProposals[member];
    }

    /**
     * @dev Get all vote records for a proposal
     * @param proposalId Proposal ID
     * @return Array of vote records
     */
    function getProposalVoteRecords(uint256 proposalId) 
        public 
        view 
        proposalExists(proposalId) 
        returns (VoteRecord[] memory) 
    {
        return proposalVoteRecords[proposalId];
    }

    /**
     * @dev Get proposals by status
     * @param status Proposal status
     * @return Array of proposal IDs
     */
    function getProposalsByStatus(ProposalStatus status) public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < proposalIdCounter; i++) {
            if (proposals[i].exists && proposals[i].status == status) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < proposalIdCounter; i++) {
            if (proposals[i].exists && proposals[i].status == status) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get all active proposals
     * @return Array of active proposal IDs
     */
    function getActiveProposals() public view returns (uint256[] memory) {
        return getProposalsByStatus(ProposalStatus.ACTIVE);
    }

    /**
     * @dev Get total number of proposals
     * @return Total proposal count
     */
    function getTotalProposals() public view returns (uint256) {
        return proposalIdCounter - 1;
    }

    /**
     * @dev Check if proposal has reached quorum
     * @param proposalId Proposal ID
     * @return true if quorum reached
     */
    function hasReachedQuorum(uint256 proposalId) 
        public 
        view 
        proposalExists(proposalId) 
        returns (bool) 
    {
        Proposal memory proposal = proposals[proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        uint256 quorumRequired = (totalMembers * quorumPercentage) / 100;
        return totalVotes >= quorumRequired;
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
        return block.timestamp > proposals[proposalId].votingEndTime;
    }

    /**
     * @dev Get time remaining for voting
     * @param proposalId Proposal ID
     * @return Seconds remaining (0 if ended)
     */
    function getTimeRemaining(uint256 proposalId) 
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
}
