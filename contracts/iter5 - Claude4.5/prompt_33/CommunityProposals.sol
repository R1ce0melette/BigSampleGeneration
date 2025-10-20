// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    address public owner;
    uint256 public constant VOTING_PERIOD = 7 days;
    
    enum ProposalStatus { ACTIVE, PASSED, REJECTED, EXECUTED }
    
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
        mapping(address => bool) voteChoice;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public isMember;
    mapping(address => uint256[]) public memberProposals;
    
    address[] public members;
    
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus status);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true;
        members.push(msg.sender);
    }
    
    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Invalid member address");
        require(!isMember[_member], "Already a member");
        
        isMember[_member] = true;
        members.push(_member);
        
        emit MemberAdded(_member);
    }
    
    function removeMember(address _member) external onlyOwner {
        require(_member != owner, "Cannot remove owner");
        require(isMember[_member], "Not a member");
        
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
    
    function submitProposal(string memory _title, string memory _description) external onlyMember {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + VOTING_PERIOD;
        newProposal.status = ProposalStatus.ACTIVE;
        
        memberProposals[msg.sender].push(proposalCount);
        
        emit ProposalSubmitted(proposalCount, msg.sender, _title);
    }
    
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.voteChoice[msg.sender] = _support;
        
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support);
    }
    
    function finalizeProposal(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.PASSED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        
        emit ProposalStatusChanged(_proposalId, proposal.status);
    }
    
    function executeProposal(uint256 _proposalId) external onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.PASSED, "Proposal has not passed");
        
        proposal.status = ProposalStatus.EXECUTED;
        
        emit ProposalStatusChanged(_proposalId, ProposalStatus.EXECUTED);
    }
    
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 endTime,
        ProposalStatus status
    ) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.endTime,
            proposal.status
        );
    }
    
    function hasVoted(uint256 _proposalId, address _member) external view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        return proposals[_proposalId].hasVoted[_member];
    }
    
    function getVoteChoice(uint256 _proposalId, address _member) external view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        require(proposals[_proposalId].hasVoted[_member], "Member has not voted");
        return proposals[_proposalId].voteChoice[_member];
    }
    
    function getMemberProposals(address _member) external view returns (uint256[] memory) {
        return memberProposals[_member];
    }
    
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE && block.timestamp <= proposals[i].endTime) {
                activeCount++;
            }
        }
        
        uint256[] memory activeProposalIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE && block.timestamp <= proposals[i].endTime) {
                activeProposalIds[index] = i;
                index++;
            }
        }
        
        return activeProposalIds;
    }
    
    function getPassedProposals() external view returns (uint256[] memory) {
        uint256 passedCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PASSED) {
                passedCount++;
            }
        }
        
        uint256[] memory passedProposalIds = new uint256[](passedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.PASSED) {
                passedProposalIds[index] = i;
                index++;
            }
        }
        
        return passedProposalIds;
    }
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }
    
    function timeRemainingToVote(uint256 _proposalId) external view returns (uint256) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        if (block.timestamp >= proposal.endTime) {
            return 0;
        }
        
        return proposal.endTime - block.timestamp;
    }
}
