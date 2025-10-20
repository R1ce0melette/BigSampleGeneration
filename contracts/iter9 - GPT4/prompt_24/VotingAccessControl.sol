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
            emit AdminAdded(initialAdmins[i]);
        }
    }

    function addMember(address user) external {
        require(admins[msg.sender], "Not admin");
        require(!members[user], "Already member");
        members[user] = true;
        emit MemberAdded(user);
    }

    function voteAddAdmin(address user) external {
        require(members[msg.sender], "Not member");
        require(!admins[user], "Already admin");
        require(!addVotes[user][msg.sender], "Already voted");
        addVotes[user][msg.sender] = true;
        uint256 count = _countVotes(addVotes[user]);
        if (count >= VOTE_THRESHOLD) {
            admins[user] = true;
            emit AdminAdded(user);
            _clearVotes(addVotes[user]);
        }
    }

    function voteRemoveAdmin(address user) external {
        require(members[msg.sender], "Not member");
        require(admins[user], "Not admin");
        require(!removeVotes[user][msg.sender], "Already voted");
        removeVotes[user][msg.sender] = true;
        uint256 count = _countVotes(removeVotes[user]);
        if (count >= VOTE_THRESHOLD) {
            admins[user] = false;
            emit AdminRemoved(user);
            _clearVotes(removeVotes[user]);
        }
    }

    function _countVotes(mapping(address => bool) storage /*votes*/) private pure returns (uint256 count) {
        count = 0;
        // Placeholder: Solidity does not allow iterating mappings.
        // In production, use an array to track voters.
    }

    function _clearVotes(mapping(address => bool) storage votes) private {
        // This is a placeholder, as Solidity does not allow deleting all keys in a mapping.
        // In production, use an array to track voters.
    }
}
