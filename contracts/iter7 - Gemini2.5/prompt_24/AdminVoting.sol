// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AdminVoting
 * @dev A contract for managing a list of admins through a voting process.
 * Existing admins can vote to add or remove other admins.
 */
contract AdminVoting {
    // List of addresses that are admins.
    mapping(address => bool) public isAdmin;
    address[] public adminList;

    // Struct for proposals to add or remove admins.
    struct Proposal {
        address candidate;
        bool isAddProposal; // true for adding, false for removing
        uint256 votes;
        mapping(address => bool) hasVoted;
    }

    // Mapping from a candidate address to an active proposal.
    mapping(address => Proposal) public proposals;

    // The required number of votes to pass a proposal.
    uint256 public requiredVotes;

    /**
     * @dev Emitted when a new proposal is created.
     * @param candidate The address of the candidate for admin change.
     * @param proposer The admin who created the proposal.
     * @param isAdd True if it's a proposal to add, false to remove.
     */
    event ProposalCreated(address indexed candidate, address indexed proposer, bool isAdd);

    /**
     * @dev Emitted when an admin votes on a proposal.
     * @param candidate The candidate of the proposal.
     * @param voter The admin who voted.
     */
    event Voted(address indexed candidate, address indexed voter);

    /**
     * @dev Emitted when a proposal is executed.
     * @param candidate The candidate of the executed proposal.
     * @param isAdd True if the candidate was added, false if removed.
     */
    event ProposalExecuted(address indexed candidate, bool isAdd);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "AdminVoting: Caller is not an admin.");
        _;
    }

    /**
     * @dev Initializes the contract with the first admin (the deployer).
     */
    constructor() {
        isAdmin[msg.sender] = true;
        adminList.push(msg.sender);
        updateRequiredVotes();
    }

    /**
     * @dev Creates a proposal to add a new admin.
     * @param _candidate The address of the user to be proposed as an admin.
     */
    function proposeAddAdmin(address _candidate) public onlyAdmin {
        require(!isAdmin[_candidate], "Candidate is already an admin.");
        require(proposals[_candidate].candidate == address(0), "A proposal for this candidate already exists.");

        proposals[_candidate] = Proposal({
            candidate: _candidate,
            isAddProposal: true,
            votes: 0
        });
        emit ProposalCreated(_candidate, msg.sender, true);
    }

    /**
     * @dev Creates a proposal to remove an existing admin.
     * @param _candidate The address of the admin to be removed.
     */
    function proposeRemoveAdmin(address _candidate) public onlyAdmin {
        require(isAdmin[_candidate], "Candidate is not an admin.");
        require(proposals[_candidate].candidate == address(0), "A proposal for this candidate already exists.");

        proposals[_candidate] = Proposal({
            candidate: _candidate,
            isAddProposal: false,
            votes: 0
        });
        emit ProposalCreated(_candidate, msg.sender, false);
    }

    /**
     * @dev Allows an admin to vote on an active proposal.
     * @param _candidate The address of the candidate in the proposal.
     */
    function vote(address _candidate) public onlyAdmin {
        Proposal storage p = proposals[_candidate];
        require(p.candidate != address(0), "No proposal found for this candidate.");
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_candidate, msg.sender);

        if (p.votes >= requiredVotes) {
            executeProposal(_candidate);
        }
    }

    /**
     * @dev Executes a proposal that has reached the required number of votes.
     * @param _candidate The address of the candidate in the proposal.
     */
    function executeProposal(address _candidate) private {
        Proposal storage p = proposals[_candidate];
        
        if (p.isAddProposal) {
            isAdmin[_candidate] = true;
            adminList.push(_candidate);
        } else {
            isAdmin[_candidate] = false;
            // Remove from adminList
            for (uint i = 0; i < adminList.length; i++) {
                if (adminList[i] == _candidate) {
                    adminList[i] = adminList[adminList.length - 1];
                    adminList.pop();
                    break;
                }
            }
        }

        emit ProposalExecuted(_candidate, p.isAddProposal);
        delete proposals[_candidate];
        updateRequiredVotes();
    }

    /**
     * @dev Updates the number of required votes based on the number of admins (majority).
     */
    function updateRequiredVotes() private {
        requiredVotes = (adminList.length / 2) + 1;
    }

    /**
     * @dev Returns the list of current admins.
     */
    function getAdmins() public view returns (address[] memory) {
        return adminList;
    }
}
