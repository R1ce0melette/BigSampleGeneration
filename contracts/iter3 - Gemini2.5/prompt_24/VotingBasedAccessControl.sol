// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VotingBasedAccessControl
 * @dev A contract for a voting-based access control system where members
 * can vote to add or remove other members (admins).
 */
contract VotingBasedAccessControl {
    enum VoteType { Add, Remove }

    struct Proposal {
        uint256 id;
        VoteType voteType;
        address candidate;
        uint256 yesVotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    address public owner;
    mapping(address => bool) public isMember;
    uint256 public memberCount;
    uint256 public proposalCounter;
    Proposal[] public proposals;

    /**
     * @dev Emitted when a new proposal is created.
     * @param proposalId The ID of the proposal.
     * @param candidate The address being proposed to be added or removed.
     * @param voteType The type of vote (Add or Remove).
     */
    event ProposalCreated(uint256 indexed proposalId, address indexed candidate, VoteType voteType);

    /**
     * @dev Emitted when a member casts a vote on a proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address of the member who voted.
     */
    event Voted(uint256 indexed proposalId, address indexed voter);

    /**
     * @dev Emitted when a proposal is executed.
     * @param proposalId The ID of the proposal.
     */
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true;
        memberCount = 1;
    }

    function createProposal(address _candidate, VoteType _voteType) public onlyMember {
        require(_candidate != address(0), "Candidate cannot be the zero address.");
        if (_voteType == VoteType.Add) {
            require(!isMember[_candidate], "Candidate is already a member.");
        } else {
            require(isMember[_candidate], "Candidate is not a member.");
            require(_candidate != owner, "Cannot remove the contract owner.");
        }

        proposalCounter++;
        Proposal storage newProposal = proposals.push();
        newProposal.id = proposalCounter;
        newProposal.voteType = _voteType;
        newProposal.candidate = _candidate;
        newProposal.executed = false;

        emit ProposalCreated(proposalCounter, _candidate, _voteType);
    }

    function vote(uint256 _proposalId) public onlyMember {
        require(_proposalId > 0 && _proposalId <= proposals.length, "Invalid proposal ID.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.yesVotes++;

        emit Voted(_proposalId, msg.sender);
    }

    function executeProposal(uint256 _proposalId) public onlyMember {
        require(_proposalId > 0 && _proposalId <= proposals.length, "Invalid proposal ID.");
        Proposal storage p = proposals[_proposalId - 1];
        require(!p.executed, "Proposal has already been executed.");
        
        // Majority vote required
        require(p.yesVotes * 2 > memberCount, "Majority vote not reached.");

        p.executed = true;
        if (p.voteType == VoteType.Add) {
            isMember[p.candidate] = true;
            memberCount++;
        } else {
            isMember[p.candidate] = false;
            memberCount--;
        }

        emit ProposalExecuted(_proposalId);
    }

    function getProposal(uint256 _proposalId) public view returns (uint256, VoteType, address, uint256, bool) {
        require(_proposalId > 0 && _proposalId <= proposals.length, "Invalid proposal ID.");
        Proposal storage p = proposals[_proposalId - 1];
        return (p.id, p.voteType, p.candidate, p.yesVotes, p.executed);
    }
}
