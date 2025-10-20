// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityProposals {
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 votes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    address[] public members;
    mapping(address => bool) public isMember;
    Proposal[] public proposals;
    uint256 public proposalCount;

    event MemberAdded(address indexed member);
    event ProposalSubmitted(uint256 indexed id, string description, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter);

    constructor() {
        // The contract deployer is the first member
        isMember[msg.sender] = true;
        members.push(msg.sender);
        emit MemberAdded(msg.sender);
    }

    function addMember(address _newMember) public {
        // For simplicity, only existing members can add new ones.
        // A more robust system might have its own voting for new members.
        require(isMember[msg.sender], "Only members can add new members.");
        require(!isMember[_newMember], "Address is already a member.");
        
        isMember[_newMember] = true;
        members.push(_newMember);
        emit MemberAdded(_newMember);
    }

    function submitProposal(string memory _description) public {
        require(isMember[msg.sender], "Only members can submit proposals.");
        
        proposals.push(Proposal({
            id: proposalCount,
            description: _description,
            proposer: msg.sender,
            votes: 0,
            executed: false
        }));
        
        emit ProposalSubmitted(proposalCount, _description, msg.sender);
        proposalCount++;
    }

    function vote(uint256 _proposalId) public {
        require(isMember[msg.sender], "Only members can vote.");
        require(_proposalId < proposals.length, "Proposal does not exist.");
        
        Proposal storage p = proposals[_proposalId];
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");

        p.hasVoted[msg.sender] = true;
        p.votes++;
        
        emit Voted(_proposalId, msg.sender);
    }

    // In a real-world scenario, you would have a function to execute proposals
    // that reach a certain threshold of votes. This is omitted for simplicity.
}
