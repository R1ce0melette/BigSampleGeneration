// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        string description;
        address proposer;
        uint256 votes;
        bool exists;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public members;
    mapping(uint256 => mapping(address => bool)) public voted;
    uint256 public nextProposalId;

    event MemberAdded(address indexed member);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter);

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    constructor(address[] memory initialMembers) {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            members[initialMembers[i]] = true;
            emit MemberAdded(initialMembers[i]);
        }
    }

    function addMember(address user) external onlyMember {
        require(!members[user], "Already a member");
        members[user] = true;
        emit MemberAdded(user);
    }

    function submitProposal(string calldata description) external onlyMember {
        proposals[nextProposalId] = Proposal({
            description: description,
            proposer: msg.sender,
            votes: 0,
            exists: true
        });
        emit ProposalSubmitted(nextProposalId, msg.sender, description);
        nextProposalId++;
    }

    function vote(uint256 proposalId) external onlyMember {
        require(proposals[proposalId].exists, "Proposal does not exist");
        require(!voted[proposalId][msg.sender], "Already voted");
        voted[proposalId][msg.sender] = true;
        proposals[proposalId].votes++;
        emit Voted(proposalId, msg.sender);
    }

    function getProposal(uint256 proposalId) external view returns (string memory, address, uint256) {
        Proposal storage p = proposals[proposalId];
        return (p.description, p.proposer, p.votes);
    }
}
