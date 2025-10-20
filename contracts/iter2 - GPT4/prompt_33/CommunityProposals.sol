// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        string description;
        uint256 votes;
        address proposer;
        bool exists;
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed proposalId, address proposer, string description);
    event Voted(uint256 indexed proposalId, address voter);

    function submitProposal(string calldata description) external {
        proposals[nextProposalId] = Proposal(description, 0, msg.sender, true);
        emit ProposalSubmitted(nextProposalId, msg.sender, description);
        nextProposalId++;
    }

    function vote(uint256 proposalId) external {
        require(proposals[proposalId].exists, "Proposal does not exist");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        proposals[proposalId].votes++;
        hasVoted[msg.sender][proposalId] = true;
        emit Voted(proposalId, msg.sender);
    }

    function getProposal(uint256 proposalId) external view returns (string memory, uint256, address) {
        Proposal storage p = proposals[proposalId];
        return (p.description, p.votes, p.proposer);
    }
}
