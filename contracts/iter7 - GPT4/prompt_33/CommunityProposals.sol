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
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public nextProposalId;

    event MemberAdded(address indexed member);
    event ProposalSubmitted(uint256 indexed id, address indexed proposer, string description);
    event Voted(uint256 indexed id, address indexed voter);

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    function addMember(address member) external {
        members[member] = true;
        emit MemberAdded(member);
    }

    function submitProposal(string calldata description) external onlyMember {
        require(bytes(description).length > 0, "Description required");
        proposals[nextProposalId] = Proposal({
            description: description,
            proposer: msg.sender,
            votes: 0,
            exists: true
        });
        emit ProposalSubmitted(nextProposalId, msg.sender, description);
        nextProposalId++;
    }

    function vote(uint256 id) external onlyMember {
        require(proposals[id].exists, "Proposal does not exist");
        require(!hasVoted[id][msg.sender], "Already voted");
        hasVoted[id][msg.sender] = true;
        proposals[id].votes++;
        emit Voted(id, msg.sender);
    }

    function getProposal(uint256 id) external view returns (string memory, address, uint256) {
        require(proposals[id].exists, "Proposal does not exist");
        Proposal storage p = proposals[id];
        return (p.description, p.proposer, p.votes);
    }
}
