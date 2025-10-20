// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        string description;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voted;
        bool exists;
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) private proposals;
    address[] public members;
    mapping(address => bool) public isMember;

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member");
        _;
    }

    constructor(address[] memory initialMembers) {
        require(initialMembers.length > 0, "At least one member");
        for (uint256 i = 0; i < initialMembers.length; i++) {
            isMember[initialMembers[i]] = true;
            members.push(initialMembers[i]);
        }
    }

    function submitProposal(string calldata description) external onlyMember {
        require(bytes(description).length > 0, "Description required");
        Proposal storage p = proposals[nextProposalId];
        p.description = description;
        p.proposer = msg.sender;
        p.exists = true;
        emit ProposalSubmitted(nextProposalId, msg.sender, description);
        nextProposalId++;
    }

    function vote(uint256 proposalId, bool support) external onlyMember {
        Proposal storage p = proposals[proposalId];
        require(p.exists, "Proposal does not exist");
        require(!p.voted[msg.sender], "Already voted");
        p.voted[msg.sender] = true;
        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }
        emit Voted(proposalId, msg.sender, support);
    }

    function getProposal(uint256 proposalId) external view returns (string memory, address, uint256, uint256) {
        Proposal storage p = proposals[proposalId];
        require(p.exists, "Proposal does not exist");
        return (p.description, p.proposer, p.votesFor, p.votesAgainst);
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }
}
