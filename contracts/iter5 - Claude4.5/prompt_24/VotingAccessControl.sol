// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    address public founder;
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant VOTE_THRESHOLD = 51; // 51% required to pass
    
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMember;
    address[] public admins;
    address[] public members;
    
    enum ProposalType { ADD_ADMIN, REMOVE_ADMIN }
    enum ProposalStatus { ACTIVE, PASSED, REJECTED, EXECUTED }
    
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address targetAddress;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    
    event MemberAdded(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed targetAddress, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(isMember[msg.sender], "Only member can call this function");
        _;
    }
    
    constructor() {
        founder = msg.sender;
        isAdmin[msg.sender] = true;
        isMember[msg.sender] = true;
        admins.push(msg.sender);
        members.push(msg.sender);
    }
    
    function addMember(address _member) external onlyAdmin {
        require(_member != address(0), "Invalid address");
        require(!isMember[_member], "Already a member");
        
        isMember[_member] = true;
        members.push(_member);
        
        emit MemberAdded(_member);
    }
    
    function createProposal(ProposalType _proposalType, address _targetAddress) external onlyMember {
        require(_targetAddress != address(0), "Invalid target address");
        require(_targetAddress != founder, "Cannot modify founder status");
        
        if (_proposalType == ProposalType.ADD_ADMIN) {
            require(!isAdmin[_targetAddress], "Already an admin");
            require(isMember[_targetAddress], "Must be a member first");
        } else if (_proposalType == ProposalType.REMOVE_ADMIN) {
            require(isAdmin[_targetAddress], "Not an admin");
            require(admins.length > 1, "Cannot remove the last admin");
        }
        
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposalType = _proposalType;
        newProposal.targetAddress = _targetAddress;
        newProposal.proposer = msg.sender;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + VOTING_PERIOD;
        newProposal.status = ProposalStatus.ACTIVE;
        
        emit ProposalCreated(proposalCount, _proposalType, _targetAddress, msg.sender);
    }
    
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support);
    }
    
    function executeProposal(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast");
        
        uint256 supportPercentage = (proposal.votesFor * 100) / totalVotes;
        
        if (supportPercentage >= VOTE_THRESHOLD) {
            proposal.status = ProposalStatus.PASSED;
            
            if (proposal.proposalType == ProposalType.ADD_ADMIN) {
                isAdmin[proposal.targetAddress] = true;
                admins.push(proposal.targetAddress);
                emit AdminAdded(proposal.targetAddress);
            } else if (proposal.proposalType == ProposalType.REMOVE_ADMIN) {
                isAdmin[proposal.targetAddress] = false;
                removeFromAdminArray(proposal.targetAddress);
                emit AdminRemoved(proposal.targetAddress);
            }
            
            proposal.status = ProposalStatus.EXECUTED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        
        emit ProposalExecuted(_proposalId, proposal.status);
    }
    
    function removeFromAdminArray(address _admin) private {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _admin) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                break;
            }
        }
    }
    
    function getProposalInfo(uint256 _proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address targetAddress,
        address proposer,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 endTime,
        ProposalStatus status
    ) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        
        Proposal storage proposal = proposals[_proposalId];
        
        return (
            proposal.id,
            proposal.proposalType,
            proposal.targetAddress,
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.endTime,
            proposal.status
        );
    }
    
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        return proposals[_proposalId].hasVoted[_voter];
    }
    
    function getAdmins() external view returns (address[] memory) {
        return admins;
    }
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getAdminCount() external view returns (uint256) {
        return admins.length;
    }
    
    function getMemberCount() external view returns (uint256) {
        return members.length;
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
}
