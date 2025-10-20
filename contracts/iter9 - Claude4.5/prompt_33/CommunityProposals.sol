// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    address public owner;
    uint256 public proposalCounter;
    uint256 public memberCounter;
    
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 votingDeadline;
        bool isActive;
        bool isExecuted;
        bool exists;
    }
    
    struct Member {
        bool isMember;
        uint256 joinedAt;
        uint256 proposalsSubmitted;
        uint256 votesParticipated;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => bool)) public voteChoice; // true = for, false = against
    
    uint256 public totalProposals;
    uint256 public totalMembers;
    uint256 public defaultVotingPeriod = 7 days;
    
    // Events
    event MemberAdded(address indexed member, uint256 timestamp);
    event MemberRemoved(address indexed member, uint256 timestamp);
    event ProposalCreated(uint256 indexed proposalId, string title, address indexed proposer, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalClosed(uint256 indexed proposalId, bool passed, uint256 votesFor, uint256 votesAgainst);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender].isMember, "Only members can call this function");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        _;
    }
    
    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(block.timestamp <= proposals[_proposalId].votingDeadline, "Voting period has ended");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Add owner as first member
        members[msg.sender] = Member({
            isMember: true,
            joinedAt: block.timestamp,
            proposalsSubmitted: 0,
            votesParticipated: 0
        });
        totalMembers = 1;
        memberCounter = 1;
        
        emit MemberAdded(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Add a new member
     * @param _member Address of the new member
     */
    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Invalid address");
        require(!members[_member].isMember, "Already a member");
        
        members[_member] = Member({
            isMember: true,
            joinedAt: block.timestamp,
            proposalsSubmitted: 0,
            votesParticipated: 0
        });
        
        totalMembers++;
        memberCounter++;
        
        emit MemberAdded(_member, block.timestamp);
    }
    
    /**
     * @dev Remove a member
     * @param _member Address of the member to remove
     */
    function removeMember(address _member) external onlyOwner {
        require(_member != owner, "Cannot remove owner");
        require(members[_member].isMember, "Not a member");
        
        members[_member].isMember = false;
        totalMembers--;
        
        emit MemberRemoved(_member, block.timestamp);
    }
    
    /**
     * @dev Submit a new proposal
     * @param _title Proposal title
     * @param _description Proposal description
     * @param _votingPeriod Custom voting period in seconds (0 for default)
     */
    function submitProposal(
        string memory _title,
        string memory _description,
        uint256 _votingPeriod
    ) external onlyMember returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        uint256 period = _votingPeriod > 0 ? _votingPeriod : defaultVotingPeriod;
        
        proposalCounter++;
        
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            title: _title,
            description: _description,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + period,
            isActive: true,
            isExecuted: false,
            exists: true
        });
        
        members[msg.sender].proposalsSubmitted++;
        totalProposals++;
        
        emit ProposalCreated(proposalCounter, _title, msg.sender, block.timestamp + period);
        
        return proposalCounter;
    }
    
    /**
     * @dev Vote on a proposal
     * @param _proposalId Proposal ID
     * @param _voteFor True to vote for, false to vote against
     */
    function vote(uint256 _proposalId, bool _voteFor) 
        external 
        onlyMember
        proposalExists(_proposalId) 
        proposalActive(_proposalId) 
    {
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");
        
        Proposal storage proposal = proposals[_proposalId];
        
        hasVoted[_proposalId][msg.sender] = true;
        voteChoice[_proposalId][msg.sender] = _voteFor;
        
        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        members[msg.sender].votesParticipated++;
        
        emit VoteCast(_proposalId, msg.sender, _voteFor);
    }
    
    /**
     * @dev Change vote on a proposal (before deadline)
     * @param _proposalId Proposal ID
     * @param _newVote New vote (true for, false against)
     */
    function changeVote(uint256 _proposalId, bool _newVote) 
        external 
        onlyMember
        proposalExists(_proposalId) 
        proposalActive(_proposalId) 
    {
        require(hasVoted[_proposalId][msg.sender], "Haven't voted yet");
        
        bool oldVote = voteChoice[_proposalId][msg.sender];
        require(oldVote != _newVote, "Same vote as before");
        
        Proposal storage proposal = proposals[_proposalId];
        
        // Remove old vote
        if (oldVote) {
            proposal.votesFor--;
        } else {
            proposal.votesAgainst--;
        }
        
        // Add new vote
        if (_newVote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        voteChoice[_proposalId][msg.sender] = _newVote;
        
        emit VoteCast(_proposalId, msg.sender, _newVote);
    }
    
    /**
     * @dev Close a proposal after voting period ends
     * @param _proposalId Proposal ID
     */
    function closeProposal(uint256 _proposalId) 
        external 
        proposalExists(_proposalId) 
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "Proposal already closed");
        require(block.timestamp > proposal.votingDeadline, "Voting period not ended");
        
        proposal.isActive = false;
        
        bool passed = proposal.votesFor > proposal.votesAgainst;
        
        emit ProposalClosed(_proposalId, passed, proposal.votesFor, proposal.votesAgainst);
    }
    
    /**
     * @dev Mark a proposal as executed (owner only)
     * @param _proposalId Proposal ID
     */
    function executeProposal(uint256 _proposalId) 
        external 
        onlyOwner
        proposalExists(_proposalId) 
    {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.isActive, "Proposal still active");
        require(!proposal.isExecuted, "Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");
        
        proposal.isExecuted = true;
        
        emit ProposalExecuted(_proposalId);
    }
    
    /**
     * @dev Cancel a proposal (only proposer or owner)
     * @param _proposalId Proposal ID
     */
    function cancelProposal(uint256 _proposalId) 
        external 
        proposalExists(_proposalId) 
    {
        Proposal storage proposal = proposals[_proposalId];
        require(
            msg.sender == proposal.proposer || msg.sender == owner,
            "Only proposer or owner can cancel"
        );
        require(proposal.isActive, "Proposal not active");
        
        proposal.isActive = false;
        
        emit ProposalClosed(_proposalId, false, proposal.votesFor, proposal.votesAgainst);
    }
    
    /**
     * @dev Update default voting period
     * @param _newPeriod New voting period in seconds
     */
    function updateVotingPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "Period must be greater than 0");
        require(_newPeriod <= 30 days, "Period cannot exceed 30 days");
        
        uint256 oldPeriod = defaultVotingPeriod;
        defaultVotingPeriod = _newPeriod;
        
        emit VotingPeriodUpdated(oldPeriod, _newPeriod);
    }
    
    /**
     * @dev Get proposal details
     * @param _proposalId Proposal ID
     */
    function getProposal(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId) 
        returns (
            uint256 id,
            string memory title,
            string memory description,
            address proposer,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 createdAt,
            uint256 votingDeadline,
            bool isActive,
            bool isExecuted
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.votingDeadline,
            proposal.isActive,
            proposal.isExecuted
        );
    }
    
    /**
     * @dev Check if proposal passed
     * @param _proposalId Proposal ID
     */
    function didProposalPass(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId) 
        returns (bool) 
    {
        Proposal memory proposal = proposals[_proposalId];
        return proposal.votesFor > proposal.votesAgainst;
    }
    
    /**
     * @dev Get voting status for a proposal
     * @param _proposalId Proposal ID
     */
    function getVotingStatus(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId) 
        returns (
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 totalVotes,
            bool isActive,
            uint256 timeRemaining
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        uint256 timeLeft = 0;
        
        if (block.timestamp < proposal.votingDeadline) {
            timeLeft = proposal.votingDeadline - block.timestamp;
        }
        
        return (
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.votesFor + proposal.votesAgainst,
            proposal.isActive && block.timestamp <= proposal.votingDeadline,
            timeLeft
        );
    }
    
    /**
     * @dev Check if an address has voted on a proposal
     * @param _proposalId Proposal ID
     * @param _voter Voter address
     */
    function hasUserVoted(uint256 _proposalId, address _voter) 
        external 
        view 
        returns (bool voted, bool voteFor) 
    {
        return (hasVoted[_proposalId][_voter], voteChoice[_proposalId][_voter]);
    }
    
    /**
     * @dev Get member details
     * @param _member Member address
     */
    function getMemberInfo(address _member) 
        external 
        view 
        returns (
            bool isMember,
            uint256 joinedAt,
            uint256 proposalsSubmitted,
            uint256 votesParticipated
        ) 
    {
        Member memory member = members[_member];
        return (
            member.isMember,
            member.joinedAt,
            member.proposalsSubmitted,
            member.votesParticipated
        );
    }
    
    /**
     * @dev Check if address is a member
     * @param _address Address to check
     */
    function isMember(address _address) external view returns (bool) {
        return members[_address].isMember;
    }
    
    /**
     * @dev Get all active proposals (returns IDs)
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active proposals
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].exists && 
                proposals[i].isActive && 
                block.timestamp <= proposals[i].votingDeadline) {
                activeCount++;
            }
        }
        
        // Create array of active proposal IDs
        uint256[] memory activeProposals = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].exists && 
                proposals[i].isActive && 
                block.timestamp <= proposals[i].votingDeadline) {
                activeProposals[index] = i;
                index++;
            }
        }
        
        return activeProposals;
    }
    
    /**
     * @dev Get all closed proposals (returns IDs)
     */
    function getClosedProposals() external view returns (uint256[] memory) {
        uint256 closedCount = 0;
        
        // Count closed proposals
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].exists && !proposals[i].isActive) {
                closedCount++;
            }
        }
        
        // Create array of closed proposal IDs
        uint256[] memory closedProposals = new uint256[](closedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].exists && !proposals[i].isActive) {
                closedProposals[index] = i;
                index++;
            }
        }
        
        return closedProposals;
    }
    
    /**
     * @dev Get contract statistics
     */
    function getStatistics() external view returns (
        uint256 _totalMembers,
        uint256 _totalProposals,
        uint256 _activeProposals,
        uint256 _defaultVotingPeriod
    ) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].exists && 
                proposals[i].isActive && 
                block.timestamp <= proposals[i].votingDeadline) {
                activeCount++;
            }
        }
        
        return (
            totalMembers,
            totalProposals,
            activeCount,
            defaultVotingPeriod
        );
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        require(members[_newOwner].isMember, "New owner must be a member");
        
        owner = _newOwner;
    }
}
