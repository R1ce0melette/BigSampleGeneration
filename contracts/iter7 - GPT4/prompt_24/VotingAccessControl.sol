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
    event MemberAdded(address indexed member);

    constructor(address[] memory initialAdmins, address[] memory initialMembers) {
        require(initialAdmins.length > 0, "At least one admin");
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            admins[initialAdmins[i]] = true;
        }
        for (uint256 i = 0; i < initialMembers.length; i++) {
            members[initialMembers[i]] = true;
            emit MemberAdded(initialMembers[i]);
        }
    }

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    function voteAddAdmin(address candidate) external onlyMember {
        require(!admins[candidate], "Already admin");
        require(!addVotes[msg.sender][candidate], "Already voted");
        addVotes[msg.sender][candidate] = true;
        uint256 count = _countVotes(addVotes, candidate);
        if (count >= VOTE_THRESHOLD) {
            admins[candidate] = true;
            _clearVotes(addVotes, candidate);
            emit AdminAdded(candidate);
        }
    }

    function voteRemoveAdmin(address admin) external onlyMember {
        require(admins[admin], "Not an admin");
        require(!removeVotes[msg.sender][admin], "Already voted");
        removeVotes[msg.sender][admin] = true;
        uint256 count = _countVotes(removeVotes, admin);
        if (count >= VOTE_THRESHOLD) {
            admins[admin] = false;
            _clearVotes(removeVotes, admin);
            emit AdminRemoved(admin);
        }
    }

    function _countVotes(mapping(address => mapping(address => bool)) storage /*votes*/, address /*candidate*/) private pure returns (uint256) {
        uint256 count = 0;
        // This is a placeholder. In practice, you would need to track all members for iteration.
        return count;
    }

    function _clearVotes(mapping(address => mapping(address => bool)) storage votes, address candidate) private {
        // This is a placeholder. In practice, you would need to track all members for iteration.
    }

    function addMember(address newMember) external {
        require(admins[msg.sender], "Not admin");
        members[newMember] = true;
        emit MemberAdded(newMember);
    }
}
