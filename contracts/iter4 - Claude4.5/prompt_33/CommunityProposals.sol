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
        uint256 votingEndTime;
        bool isActive;
        bool isExecuted;
        ProposalStatus status;
    }
    
    struct Member {
        address memberAddress;
        bool isMember;
        uint256 proposalsSubmitted;
        uint256 votesParticipated;
        uint256 joinedAt;
    }
    
    enum ProposalStatus {
        Pending,
        Active,
        Passed,
        Rejected,
        Executed
    }
    
    address public owner;
    uint256 public totalProposals;
    uint256 public totalMembers;
    uint256 public votingPeriod; // Duration in seconds
    uint256 public quorumPercentage; // Percentage of members required to vote
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => bool)) public voteChoice; // true = for, false = against
    mapping(address => uint256[]) public memberProposals;
    mapping(uint256 => address[]) public proposalVoters;
    
    // Events
    event MemberAdded(address indexed member, uint256 timestamp);
    event MemberRemoved(address indexed member, uint256 timestamp);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 votingEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteFor, uint256 timestamp);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender].isMember, "Only members can call this function");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId != 0, "Proposal does not exist");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     * @param _votingPeriod The voting period in seconds
     * @param _quorumPercentage The quorum percentage required
     */
    constructor(uint256 _votingPeriod, uint256 _quorumPercentage) {
        owner = msg.sender;
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        
        // Automatically add owner as first member
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            isMember: true,
            proposalsSubmitted: 0,
            votesParticipated: 0,
            joinedAt: block.timestamp
        });
        totalMembers++;
    }
    
    /**
     * @dev Adds a new member to the community
     * @param _member The address of the member to add
     */
    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Invalid member address");
        require(!members[_member].isMember, "Already a member");
        
        members[_member] = Member({
            memberAddress: _member,
            isMember: true,
            proposalsSubmitted: 0,
            votesParticipated: 0,
            joinedAt: block.timestamp
        });
        
        totalMembers++;
        
        emit MemberAdded(_member, block.timestamp);
    }
    
    /**
     * @dev Removes a member from the community
     * @param _member The address of the member to remove
     */
    function removeMember(address _member) external onlyOwner {
        require(members[_member].isMember, "Not a member");
        require(_member != owner, "Cannot remove owner");
        
        members[_member].isMember = false;
        totalMembers--;
        
        emit MemberRemoved(_member, block.timestamp);
    }
    
    /**
     * @dev Submits a new proposal
     * @param _title The title of the proposal
     * @param _description The description of the proposal
     */
    function submitProposal(
        string memory _title,
        string memory _description
    ) external onlyMember returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        totalProposals++;
        uint256 proposalId = totalProposals;
        
        uint256 endTime = block.timestamp + votingPeriod;
        
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            votingEndTime: endTime,
            isActive: true,
            isExecuted: false,
            status: ProposalStatus.Active
        });
        
        members[msg.sender].proposalsSubmitted++;
        memberProposals[msg.sender].push(proposalId);
        
        emit ProposalSubmitted(proposalId, msg.sender, _title, endTime);
        
        return proposalId;
    }
    
    /**
     * @dev Casts a vote on a proposal
     * @param _proposalId The ID of the proposal
     * @param _voteFor True to vote for, false to vote against
     */
    function vote(uint256 _proposalId, bool _voteFor) external onlyMember proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.isActive, "Proposal is not active");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");
        
        hasVoted[_proposalId][msg.sender] = true;
        voteChoice[_proposalId][msg.sender] = _voteFor;
        
        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        members[msg.sender].votesParticipated++;
        proposalVoters[_proposalId].push(msg.sender);
        
        emit VoteCast(_proposalId, msg.sender, _voteFor, block.timestamp);
    }
    
    /**
     * @dev Finalizes a proposal after the voting period ends
     * @param _proposalId The ID of the proposal
     */
    function finalizeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.isActive, "Proposal is not active");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended");
        
        proposal.isActive = false;
        
        // Check if quorum is met
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;
        
        if (totalVotes >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Passed;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        
        emit ProposalStatusChanged(_proposalId, proposal.status);
    }
    
    /**
     * @dev Executes a passed proposal (owner only)
     * @param _proposalId The ID of the proposal
     */
    function executeProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(!proposal.isActive, "Proposal still active");
        require(proposal.status == ProposalStatus.Passed, "Proposal did not pass");
        require(!proposal.isExecuted, "Proposal already executed");
        
        proposal.isExecuted = true;
        proposal.status = ProposalStatus.Executed;
        
        emit ProposalExecuted(_proposalId, msg.sender);
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Executed);
    }
    
    /**
     * @dev Returns proposal details
     * @param _proposalId The ID of the proposal
     * @return proposalId The proposal ID
     * @return proposer The proposer's address
     * @return title The proposal title
     * @return description The proposal description
     * @return votesFor Number of votes for
     * @return votesAgainst Number of votes against
     * @return createdAt When the proposal was created
     * @return votingEndTime When voting ends
     * @return isActive Whether the proposal is active
     * @return isExecuted Whether the proposal is executed
     * @return status The proposal status
     */
    function getProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (
        uint256 proposalId,
        address proposer,
        string memory title,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 createdAt,
        uint256 votingEndTime,
        bool isActive,
        bool isExecuted,
        ProposalStatus status
    ) {
        Proposal memory proposal = proposals[_proposalId];
        
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.votingEndTime,
            proposal.isActive,
            proposal.isExecuted,
            proposal.status
        );
    }
    
    /**
     * @dev Returns member details
     * @param _member The address of the member
     * @return memberAddress The member's address
     * @return isMember Whether the address is a member
     * @return proposalsSubmitted Number of proposals submitted
     * @return votesParticipated Number of votes participated in
     * @return joinedAt When the member joined
     */
    function getMember(address _member) external view returns (
        address memberAddress,
        bool isMember,
        uint256 proposalsSubmitted,
        uint256 votesParticipated,
        uint256 joinedAt
    ) {
        Member memory member = members[_member];
        
        return (
            member.memberAddress,
            member.isMember,
            member.proposalsSubmitted,
            member.votesParticipated,
            member.joinedAt
        );
    }
    
    /**
     * @dev Returns all proposals submitted by a member
     * @param _member The address of the member
     * @return Array of proposal IDs
     */
    function getMemberProposals(address _member) external view returns (uint256[] memory) {
        return memberProposals[_member];
    }
    
    /**
     * @dev Returns all voters for a proposal
     * @param _proposalId The ID of the proposal
     * @return Array of voter addresses
     */
    function getProposalVoters(uint256 _proposalId) external view proposalExists(_proposalId) returns (address[] memory) {
        return proposalVoters[_proposalId];
    }
    
    /**
     * @dev Checks if an address has voted on a proposal
     * @param _proposalId The ID of the proposal
     * @param _voter The address of the voter
     * @return True if voted, false otherwise
     */
    function hasAddressVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        return hasVoted[_proposalId][_voter];
    }
    
    /**
     * @dev Gets the vote choice of an address
     * @param _proposalId The ID of the proposal
     * @param _voter The address of the voter
     * @return True if voted for, false if voted against
     */
    function getVoteChoice(uint256 _proposalId, address _voter) external view returns (bool) {
        require(hasVoted[_proposalId][_voter], "Address has not voted");
        return voteChoice[_proposalId][_voter];
    }
    
    /**
     * @dev Returns all active proposals
     * @return Array of proposal IDs
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalProposals; i++) {
            if (proposals[i].isActive) {
                count++;
            }
        }
        
        uint256[] memory activeProposals = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalProposals; i++) {
            if (proposals[i].isActive) {
                activeProposals[index] = i;
                index++;
            }
        }
        
        return activeProposals;
    }
    
    /**
     * @dev Returns all passed proposals
     * @return Array of proposal IDs
     */
    function getPassedProposals() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalProposals; i++) {
            if (proposals[i].status == ProposalStatus.Passed) {
                count++;
            }
        }
        
        uint256[] memory passedProposals = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalProposals; i++) {
            if (proposals[i].status == ProposalStatus.Passed) {
                passedProposals[index] = i;
                index++;
            }
        }
        
        return passedProposals;
    }
    
    /**
     * @dev Returns the time remaining for voting on a proposal
     * @param _proposalId The ID of the proposal
     * @return Time remaining in seconds (0 if ended)
     */
    function getTimeRemaining(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256) {
        if (block.timestamp >= proposals[_proposalId].votingEndTime) {
            return 0;
        }
        
        return proposals[_proposalId].votingEndTime - block.timestamp;
    }
    
    /**
     * @dev Checks if a member is registered
     * @param _member The address of the member
     * @return True if member, false otherwise
     */
    function isMemberRegistered(address _member) external view returns (bool) {
        return members[_member].isMember;
    }
    
    /**
     * @dev Returns the total number of proposals
     * @return Total number of proposals
     */
    function getTotalProposals() external view returns (uint256) {
        return totalProposals;
    }
    
    /**
     * @dev Returns the total number of members
     * @return Total number of members
     */
    function getTotalMembers() external view returns (uint256) {
        return totalMembers;
    }
    
    /**
     * @dev Returns the voting period duration
     * @return Voting period in seconds
     */
    function getVotingPeriod() external view returns (uint256) {
        return votingPeriod;
    }
    
    /**
     * @dev Returns the quorum percentage
     * @return Quorum percentage
     */
    function getQuorumPercentage() external view returns (uint256) {
        return quorumPercentage;
    }
    
    /**
     * @dev Updates the voting period (owner only)
     * @param _newVotingPeriod The new voting period in seconds
     */
    function updateVotingPeriod(uint256 _newVotingPeriod) external onlyOwner {
        require(_newVotingPeriod > 0, "Voting period must be greater than 0");
        votingPeriod = _newVotingPeriod;
    }
    
    /**
     * @dev Updates the quorum percentage (owner only)
     * @param _newQuorumPercentage The new quorum percentage
     */
    function updateQuorumPercentage(uint256 _newQuorumPercentage) external onlyOwner {
        require(_newQuorumPercentage > 0 && _newQuorumPercentage <= 100, "Invalid quorum percentage");
        quorumPercentage = _newQuorumPercentage;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
