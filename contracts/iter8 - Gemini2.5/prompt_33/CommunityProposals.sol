// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CommunityProposals
 * @dev A contract for managing community-driven proposals.
 * Members can submit proposals and vote on them.
 */
contract CommunityProposals {
    address public owner;
    uint256 public proposalCounter;
    uint256 public memberCount;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(address => bool) public isMember;
    mapping(uint256 => Proposal) public proposals;

    event MemberAdded(address indexed newMember);
    event MemberRemoved(address indexed removedMember);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        // The deployer is the first member
        isMember[msg.sender] = true;
        memberCount = 1;
        emit MemberAdded(msg.sender);
    }

    /**
     * @dev Allows the owner to add a new member to the community.
     * @param _newMember The address of the new member.
     */
    function addMember(address _newMember) external onlyOwner {
        require(_newMember != address(0), "Cannot add the zero address.");
        require(!isMember[_newMember], "Address is already a member.");
        
        isMember[_newMember] = true;
        memberCount++;
        emit MemberAdded(_newMember);
    }

    /**
     * @dev Allows the owner to remove a member from the community.
     * @param _member The address of the member to remove.
     */
    function removeMember(address _member) external onlyOwner {
        require(isMember[_member], "Address is not a member.");
        
        isMember[_member] = false;
        memberCount--;
        emit MemberRemoved(_member);
    }

    /**
     * @dev Allows a member to submit a new proposal.
     * @param _description The description of the proposal.
     */
    function submitProposal(string memory _description) external onlyMember {
        require(bytes(_description).length > 0, "Description cannot be empty.");
        
        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        
        emit ProposalSubmitted(proposalCounter, msg.sender, _description);
    }

    /**
     * @dev Allows a member to vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     */
    function vote(uint256 _proposalId) external onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "Proposal does not exist.");
        require(!p.executed, "Proposal has already been executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.voteCount++;
        
        emit VotedOnProposal(_proposalId, msg.sender);
    }

    /**
     * @dev Executes a proposal if it has received enough votes (e.g., >50% of members).
     * This is a placeholder for what "execution" means. In a real DAO, this would trigger an action.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "Proposal does not exist.");
        require(!p.executed, "Proposal has already been executed.");
        require(p.voteCount * 2 > memberCount, "Proposal does not have enough votes to be executed.");

        p.executed = true;
        // In a real scenario, this function would trigger on-chain actions
        // based on the proposal's content. For this example, we just mark it as executed.
        
        emit ProposalExecuted(_proposalId);
    }

    function getProposal(uint256 _proposalId) external view returns (address, string memory, uint256, bool) {
        Proposal storage p = proposals[_proposalId];
        return (p.proposer, p.description, p.voteCount, p.executed);
    }
}
