// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CommunityProposals
 * @dev A contract for managing community proposals. Members can submit proposals and vote on them.
 */
contract CommunityProposals {
    // The address of the contract owner/moderator.
    address public owner;

    // Struct to represent a proposal.
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 voteCount;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // Counter for generating unique proposal IDs.
    uint256 private _proposalIds;

    // Mapping from proposal ID to the Proposal struct.
    mapping(uint256 => Proposal) public proposals;

    // List of members who are eligible to vote.
    mapping(address => bool) public isMember;

    /**
     * @dev Emitted when a new proposal is submitted.
     * @param proposalId The unique ID of the proposal.
     * @param proposer The address of the member who submitted the proposal.
     * @param title The title of the proposal.
     */
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title);

    /**
     * @dev Emitted when a member votes on a proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address of the member who voted.
     */
    event Voted(uint256 indexed proposalId, address indexed voter);

    modifier onlyOwner() {
        require(msg.sender == owner, "CommunityProposals: Caller is not the owner.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "CommunityProposals: Caller is not a member.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true; // The owner is the first member.
    }

    /**
     * @dev Allows the owner to add a new member.
     * @param _newMember The address of the new member.
     */
    function addMember(address _newMember) public onlyOwner {
        require(!isMember[_newMember], "Address is already a member.");
        isMember[_newMember] = true;
    }

    /**
     * @dev Allows a member to submit a new proposal.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     */
    function submitProposal(string memory _title, string memory _description) public onlyMember {
        require(bytes(_title).length > 0, "Title cannot be empty.");
        _proposalIds++;
        uint256 newProposalId = _proposalIds;

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            voteCount: 0,
            executed: false
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _title);
    }

    /**
     * @dev Allows a member to vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     */
    function vote(uint256 _proposalId) public onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "Proposal does not exist.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.voteCount++;

        emit Voted(_proposalId, msg.sender);
    }

    /**
     * @dev A placeholder function for what happens when a proposal is executed.
     * In a real-world scenario, this would trigger some on-chain action.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "Proposal does not exist.");
        require(!p.executed, "Proposal has already been executed.");
        
        // For demonstration, we'll just mark it as executed.
        // A real implementation would have more logic here.
        p.executed = true;
    }
}
