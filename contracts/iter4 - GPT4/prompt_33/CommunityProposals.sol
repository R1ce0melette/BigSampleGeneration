// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        address proposer;
        string description;
        uint256 votes;
        bool exists;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter);

    function submitProposal(string calldata description) external {
        proposals.push(Proposal(msg.sender, description, 0, true));
        emit ProposalSubmitted(proposals.length - 1, msg.sender, description);
    }

    function vote(uint256 proposalId) external {
        require(proposalId < proposals.length, "Invalid proposal");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        require(proposals[proposalId].exists, "Proposal does not exist");
        hasVoted[msg.sender][proposalId] = true;
        proposals[proposalId].votes += 1;
        emit Voted(proposalId, msg.sender);
    }

    function getProposal(uint256 proposalId) external view returns (address, string memory, uint256, bool) {
        Proposal storage p = proposals[proposalId];
        return (p.proposer, p.description, p.votes, p.exists);
    }

    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }
}
