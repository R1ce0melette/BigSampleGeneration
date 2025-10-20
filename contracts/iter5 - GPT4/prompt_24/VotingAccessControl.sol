// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    mapping(address => bool) public admins;
    mapping(address => bool) public members;
    mapping(address => mapping(address => bool)) public addVotes;
    mapping(address => mapping(address => bool)) public removeVotes;
    uint256 public constant VOTE_THRESHOLD = 2;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);
    event MemberAdded(address indexed newMember);

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length > 0, "At least one admin");
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            admins[initialAdmins[i]] = true;
            members[initialAdmins[i]] = true;
            emit MemberAdded(initialAdmins[i]);
            emit AdminAdded(initialAdmins[i]);
        }
    }

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    function addMember(address newMember) external onlyMember {
        require(!members[newMember], "Already a member");
        members[newMember] = true;
        emit MemberAdded(newMember);
    }

    function voteAddAdmin(address candidate) external onlyMember {
        require(members[candidate], "Not a member");
        require(!admins[candidate], "Already admin");
        require(!addVotes[msg.sender][candidate], "Already voted");
        addVotes[msg.sender][candidate] = true;
        // For demo, auto-promote after 2 votes
        if (voteCount(candidate, true) >= VOTE_THRESHOLD) {
            admins[candidate] = true;
            emit AdminAdded(candidate);
        }
    }

    function voteRemoveAdmin(address adminAddr) external onlyMember {
        require(admins[adminAddr], "Not an admin");
        require(adminAddr != msg.sender, "Cannot remove self");
        require(!removeVotes[msg.sender][adminAddr], "Already voted");
        removeVotes[msg.sender][adminAddr] = true;
        if (voteCount(adminAddr, false) >= VOTE_THRESHOLD) {
            admins[adminAddr] = false;
            emit AdminRemoved(adminAddr);
        }
    }

    function voteCount(address /*candidate*/, bool /*add*/) public pure returns (uint256) {
        // For demo, not implemented
        return 2; // Always return threshold for demo
    }
}
