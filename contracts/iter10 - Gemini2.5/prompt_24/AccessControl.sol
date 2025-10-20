// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    mapping(address => bool) public members;
    mapping(address => bool) public admins;
    uint256 public memberCount;
    uint256 public adminCount;

    struct Proposal {
        address candidate;
        bool add; // true to add, false to remove
        uint256 votes;
        mapping(address => bool) hasVoted;
    }

    Proposal[] public proposals;

    event MemberAdded(address indexed member);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ProposalCreated(uint256 id, address indexed candidate, bool add);
    event Voted(uint256 proposalId, address indexed voter);

    constructor() {
        members[msg.sender] = true;
        admins[msg.sender] = true;
        memberCount = 1;
        adminCount = 1;
        emit MemberAdded(msg.sender);
        emit AdminAdded(msg.sender);
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    function createProposal(address _candidate, bool _add) public onlyMember {
        if (_add) {
            require(!admins[_candidate], "Candidate is already an admin.");
        } else {
            require(admins[_candidate], "Candidate is not an admin.");
        }
        proposals.push(Proposal({
            candidate: _candidate,
            add: _add,
            votes: 0
        }));
        emit ProposalCreated(proposals.length - 1, _candidate, _add);
    }

    function vote(uint256 _proposalId) public onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(!p.hasVoted[msg.sender], "You have already voted on this proposal.");
        
        p.hasVoted[msg.sender] = true;
        p.votes++;
        emit Voted(_proposalId, msg.sender);

        if (p.votes > adminCount / 2) {
            if (p.add) {
                admins[p.candidate] = true;
                adminCount++;
                if (!members[p.candidate]) {
                    members[p.candidate] = true;
                    memberCount++;
                    emit MemberAdded(p.candidate);
                }
                emit AdminAdded(p.candidate);
            } else {
                admins[p.candidate] = false;
                adminCount--;
                emit AdminRemoved(p.candidate);
            }
            // In a real scenario, you might want to handle the proposal differently after execution
        }
    }
}
