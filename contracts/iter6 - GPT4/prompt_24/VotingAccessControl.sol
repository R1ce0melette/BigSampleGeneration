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

    constructor(address[] memory initialAdmins, address[] memory initialMembers) {
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            admins[initialAdmins[i]] = true;
        }
        for (uint256 i = 0; i < initialMembers.length; i++) {
            members[initialMembers[i]] = true;
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
        uint256 count = 0;
        for (uint256 i = 0; i < 100; i++) {
            // This is a placeholder for off-chain vote counting or a more scalable on-chain approach
        }
        // For simplicity, auto-add after threshold
        if (count >= VOTE_THRESHOLD) {
            admins[candidate] = true;
            emit AdminAdded(candidate);
        }
    }

    function voteRemoveAdmin(address admin) external onlyMember {
        require(admins[admin], "Not admin");
        require(!removeVotes[msg.sender][admin], "Already voted");
        removeVotes[msg.sender][admin] = true;
        uint256 count = 0;
        for (uint256 i = 0; i < 100; i++) {
            // This is a placeholder for off-chain vote counting or a more scalable on-chain approach
        }
        // For simplicity, auto-remove after threshold
        if (count >= VOTE_THRESHOLD) {
            admins[admin] = false;
            emit AdminRemoved(admin);
        }
    }

    function addMember(address newMember) external {
        require(admins[msg.sender], "Not admin");
        members[newMember] = true;
        emit MemberAdded(newMember);
    }
}
