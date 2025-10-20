// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        string description;
        address proposer;
        uint256 votes;
        bool exists;
    }

    Proposal[] public proposals;
    mapping(address => bool) public isMember;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    address public owner;

    event ProposalSubmitted(uint256 indexed id, address indexed proposer, string description);
    event Voted(uint256 indexed id, address indexed voter);
    event MemberAdded(address indexed member);

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address[] memory members) {
        owner = msg.sender;
        for (uint256 i = 0; i < members.length; i++) {
            isMember[members[i]] = true;
            emit MemberAdded(members[i]);
        }
    }

    function addMember(address member) external onlyOwner {
        require(!isMember[member], "Already member");
        isMember[member] = true;
        emit MemberAdded(member);
    }

    function submitProposal(string calldata description) external onlyMember {
        proposals.push(Proposal(description, msg.sender, 0, true));
        emit ProposalSubmitted(proposals.length - 1, msg.sender, description);
    }

    function vote(uint256 id) external onlyMember {
        require(id < proposals.length, "Invalid proposal");
        require(!hasVoted[id][msg.sender], "Already voted");
        require(proposals[id].exists, "Proposal does not exist");
        hasVoted[id][msg.sender] = true;
        proposals[id].votes++;
        emit Voted(id, msg.sender);
    }

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }
}
