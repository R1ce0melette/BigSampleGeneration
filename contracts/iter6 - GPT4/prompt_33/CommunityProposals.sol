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
    mapping(address => bool) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event MemberAdded(address indexed member);

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

    function submitProposal(string calldata description) external onlyMember {
        proposals.push(Proposal({
            proposer: msg.sender,
            description: description,
            votes: 0,
            exists: true
        }));
        emit ProposalSubmitted(proposals.length - 1, msg.sender, description);
    }

    function vote(uint256 proposalId) external onlyMember {
        require(proposalId < proposals.length, "Invalid proposalId");
        require(proposals[proposalId].exists, "Proposal does not exist");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        proposals[proposalId].votes += 1;
        hasVoted[proposalId][msg.sender] = true;
        emit Voted(proposalId, msg.sender);
    }

    function getProposal(uint256 proposalId) external view returns (address, string memory, uint256, bool) {
        require(proposalId < proposals.length, "Invalid proposalId");
        Proposal storage p = proposals[proposalId];
        return (p.proposer, p.description, p.votes, p.exists);
    }

    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }
}
