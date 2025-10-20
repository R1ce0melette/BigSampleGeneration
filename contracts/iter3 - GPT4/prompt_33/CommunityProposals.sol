// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool active;
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalSubmitted(uint256 id, address indexed proposer, string description);
    event Voted(uint256 id, address indexed voter, bool support);
    event ProposalClosed(uint256 id);

    function submitProposal(string calldata description) external {
        proposals[nextProposalId] = Proposal(nextProposalId, msg.sender, description, 0, 0, true);
        emit ProposalSubmitted(nextProposalId, msg.sender, description);
        nextProposalId++;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(p.active, "Proposal closed");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        hasVoted[msg.sender][proposalId] = true;
        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }
        emit Voted(proposalId, msg.sender, support);
    }

    function closeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.active, "Already closed");
        p.active = false;
        emit ProposalClosed(proposalId);
    }

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }
}
