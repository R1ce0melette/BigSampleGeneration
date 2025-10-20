// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        string description;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool active;
    }

    Proposal[] public proposals;
    mapping(address => bool) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed proposalId, address proposer, string description);
    event Voted(uint256 indexed proposalId, address voter, bool support);

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    constructor(address[] memory initialMembers) {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            members[initialMembers[i]] = true;
        }
    }

    function submitProposal(string calldata description) external onlyMember {
        proposals.push(Proposal({
            description: description,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            active: true
        }));
        emit ProposalSubmitted(proposals.length - 1, msg.sender, description);
    }

    function vote(uint256 proposalId, bool support) external onlyMember {
        require(proposalId < proposals.length, "Invalid proposal");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        Proposal storage p = proposals[proposalId];
        require(p.active, "Proposal not active");
        hasVoted[proposalId][msg.sender] = true;
        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }
        emit Voted(proposalId, msg.sender, support);
    }

    function closeProposal(uint256 proposalId) external onlyMember {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage p = proposals[proposalId];
        require(p.active, "Already closed");
        p.active = false;
    }

    function getProposal(uint256 proposalId) external view returns (string memory, address, uint256, uint256, bool) {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage p = proposals[proposalId];
        return (p.description, p.proposer, p.votesFor, p.votesAgainst, p.active);
    }

    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }
}
