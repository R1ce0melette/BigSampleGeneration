// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    address public owner;
    
    enum ProposalStatus { PENDING, ACTIVE, PASSED, REJECTED, EXECUTED }
    
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 votingDeadline;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
        mapping(address => bool) voteChoice; // true = for, false = against
    }
    
    mapping(address => bool) public isMember;
    address[] public members;
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256[]) public userProposals;
    
    uint256 public votingPeriod = 7 days;
    uint256 public quorumPercentage = 30; // 30% of members must vote
    uint256 public approvalPercentage = 50; // 50% of votes must be in favor
    
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 votingDeadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus status);
    event ProposalExecuted(uint256 indexed proposalId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true;
        members.push(msg.sender);
    }
    
    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Member address cannot be zero");
        require(!isMember[_member], "Address is already a member");
        
        isMember[_member] = true;
        members.push(_member);
        
        emit MemberAdded(_member);
    }
    
    function removeMember(address _member) external onlyOwner {
        require(isMember[_member], "Address is not a member");
        require(_member != owner, "Cannot remove owner");
        
        isMember[_member] = false;
        
        // Remove from members array
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        
        emit MemberRemoved(_member);
    }
    
    function createProposal(string memory _title, string memory _description) external onlyMember returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.createdAt = block.timestamp;
        newProposal.votingDeadline = block.timestamp + votingPeriod;
        newProposal.status = ProposalStatus.ACTIVE;
        
        userProposals[msg.sender].push(proposalCount);
        
        emit ProposalCreated(proposalCount, msg.sender, _title, newProposal.votingDeadline);
        
        return proposalCount;
    }
    
    function vote(uint256 _proposalId, bool _support) external onlyMember proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "You have already voted");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.voteChoice[msg.sender] = _support;
        
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support);
    }
    
    function finalizeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = (members.length * quorumPercentage) / 100;
        
        if (totalVotes >= requiredQuorum) {
            uint256 requiredApproval = (totalVotes * approvalPercentage) / 100;
            
            if (proposal.votesFor > requiredApproval) {
                proposal.status = ProposalStatus.PASSED;
            } else {
                proposal.status = ProposalStatus.REJECTED;
            }
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        
        emit ProposalStatusChanged(_proposalId, proposal.status);
    }
    
    function executeProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.PASSED, "Proposal has not passed");
        
        proposal.status = ProposalStatus.EXECUTED;
        
        emit ProposalExecuted(_proposalId);
        emit ProposalStatusChanged(_proposalId, ProposalStatus.EXECUTED);
    }
    
    function getProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (
        address proposer,
        string memory title,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 createdAt,
        uint256 votingDeadline,
        ProposalStatus status
    ) {
        Proposal storage proposal = proposals[_proposalId];
        
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.createdAt,
            proposal.votingDeadline,
            proposal.status
        );
    }
    
    function hasVoted(uint256 _proposalId, address _voter) external view proposalExists(_proposalId) returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }
    
    function getVoteChoice(uint256 _proposalId, address _voter) external view proposalExists(_proposalId) returns (bool) {
        require(proposals[_proposalId].hasVoted[_voter], "Voter has not voted");
        return proposals[_proposalId].voteChoice[_voter];
    }
    
    function getUserProposals(address _user) external view returns (uint256[] memory) {
        return userProposals[_user];
    }
    
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE && block.timestamp <= proposals[i].votingDeadline) {
                activeCount++;
            }
        }
        
        uint256[] memory activeProposals = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE && block.timestamp <= proposals[i].votingDeadline) {
                activeProposals[index] = i;
                index++;
            }
        }
        
        return activeProposals;
    }
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }
    
    function updateVotingPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "Voting period must be greater than 0");
        votingPeriod = _newPeriod;
    }
    
    function updateQuorumPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage > 0 && _newPercentage <= 100, "Percentage must be between 1 and 100");
        quorumPercentage = _newPercentage;
    }
    
    function updateApprovalPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage > 0 && _newPercentage <= 100, "Percentage must be between 1 and 100");
        approvalPercentage = _newPercentage;
    }
    
    function getProposalVotingStats(uint256 _proposalId) external view proposalExists(_proposalId) returns (
        uint256 totalVotes,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 forPercentage,
        uint256 againstPercentage
    ) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 total = proposal.votesFor + proposal.votesAgainst;
        uint256 forPct = total > 0 ? (proposal.votesFor * 100) / total : 0;
        uint256 againstPct = total > 0 ? (proposal.votesAgainst * 100) / total : 0;
        
        return (
            total,
            proposal.votesFor,
            proposal.votesAgainst,
            forPct,
            againstPct
        );
    }
}
