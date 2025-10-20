// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    address public owner;

    enum ProposalStatus { PENDING, ACTIVE, APPROVED, REJECTED, EXECUTED }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        uint256 votingDeadline;
        ProposalStatus status;
        bool executed;
    }

    struct Member {
        bool isMember;
        uint256 joinedAt;
    }

    uint256 public proposalCount;
    uint256 public memberCount;
    uint256 public votingPeriod;
    uint256 public quorumPercentage;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => bool)) public voteChoice;

    address[] public memberList;

    event MemberAdded(address indexed member, uint256 timestamp);
    event MemberRemoved(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalExecuted(uint256 indexed proposalId);

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

    constructor(uint256 _votingPeriodInDays, uint256 _quorumPercentage) {
        owner = msg.sender;
        votingPeriod = _votingPeriodInDays * 1 days;
        quorumPercentage = _quorumPercentage;
        
        // Owner is automatically a member
        members[msg.sender] = Member({
            isMember: true,
            joinedAt: block.timestamp
        });
        memberList.push(msg.sender);
        memberCount = 1;
    }

    function addMember(address newMember) external onlyOwner {
        require(newMember != address(0), "Invalid address");
        require(!members[newMember].isMember, "Already a member");

        members[newMember] = Member({
            isMember: true,
            joinedAt: block.timestamp
        });
        memberList.push(newMember);
        memberCount++;

        emit MemberAdded(newMember, block.timestamp);
    }

    function removeMember(address member) external onlyOwner {
        require(members[member].isMember, "Not a member");
        require(member != owner, "Cannot remove owner");

        members[member].isMember = false;
        memberCount--;

        // Remove from member list
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MemberRemoved(member);
    }

    function submitProposal(string memory title, string memory description) external onlyMember returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");

        proposalCount++;
        uint256 deadline = block.timestamp + votingPeriod;

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            title: title,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            votingDeadline: deadline,
            status: ProposalStatus.ACTIVE,
            executed: false
        });

        emit ProposalCreated(proposalCount, msg.sender, title, deadline);

        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) external onlyMember proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        hasVoted[proposalId][msg.sender] = true;
        voteChoice[proposalId][msg.sender] = support;

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    function finalizeProposal(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumRequired = (memberCount * quorumPercentage) / 100;

        if (totalVotes < quorumRequired) {
            proposal.status = ProposalStatus.REJECTED;
        } else if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.APPROVED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }

        emit ProposalStatusChanged(proposalId, proposal.status);
    }

    function executeProposal(uint256 proposalId) external onlyOwner proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.status == ProposalStatus.APPROVED, "Proposal is not approved");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        proposal.status = ProposalStatus.EXECUTED;

        emit ProposalExecuted(proposalId);
        emit ProposalStatusChanged(proposalId, ProposalStatus.EXECUTED);
    }

    function getProposal(uint256 proposalId) external view proposalExists(proposalId) returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votingDeadline,
        ProposalStatus status,
        bool executed
    ) {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.votingDeadline,
            proposal.status,
            proposal.executed
        );
    }

    function hasUserVoted(uint256 proposalId, address voter) external view proposalExists(proposalId) returns (bool) {
        return hasVoted[proposalId][voter];
    }

    function getUserVote(uint256 proposalId, address voter) external view proposalExists(proposalId) returns (bool support, bool voted) {
        if (!hasVoted[proposalId][voter]) {
            return (false, false);
        }
        return (voteChoice[proposalId][voter], true);
    }

    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE && block.timestamp <= proposals[i].votingDeadline) {
                activeCount++;
            }
        }

        uint256[] memory activeProposalIds = new uint256[](activeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE && block.timestamp <= proposals[i].votingDeadline) {
                activeProposalIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return activeProposalIds;
    }

    function getMembers() external view returns (address[] memory) {
        return memberList;
    }

    function isMember(address account) external view returns (bool) {
        return members[account].isMember;
    }

    function updateVotingPeriod(uint256 newPeriodInDays) external onlyOwner {
        require(newPeriodInDays > 0, "Period must be greater than 0");
        votingPeriod = newPeriodInDays * 1 days;
    }

    function updateQuorumPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage > 0 && newPercentage <= 100, "Invalid percentage");
        quorumPercentage = newPercentage;
    }
}
