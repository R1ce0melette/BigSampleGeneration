// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        string description;
        uint256 votes;
        bool active;
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed id, string description);
    event Voted(address indexed voter, uint256 indexed proposalId);
    event ProposalClosed(uint256 indexed id);

    function submitProposal(string calldata description) external {
        require(bytes(description).length > 0, "Description required");
        proposals[nextProposalId] = Proposal(description, 0, true);
        emit ProposalSubmitted(nextProposalId, description);
        nextProposalId++;
    }

    function vote(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.active, "Proposal closed");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        hasVoted[msg.sender][proposalId] = true;
        p.votes += 1;
        emit Voted(msg.sender, proposalId);
    }

    function closeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.active, "Already closed");
        p.active = false;
        emit ProposalClosed(proposalId);
    }

    function getProposal(uint256 proposalId) external view returns (string memory, uint256, bool) {
        Proposal storage p = proposals[proposalId];
        return (p.description, p.votes, p.active);
    }
}
