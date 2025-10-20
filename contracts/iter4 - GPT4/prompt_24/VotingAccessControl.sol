// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    mapping(address => bool) public admins;
    mapping(address => mapping(address => bool)) public addVotes;
    mapping(address => mapping(address => bool)) public removeVotes;
    uint256 public constant VOTE_THRESHOLD = 2;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);

    constructor(address[] memory initialAdmins) {
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            admins[initialAdmins[i]] = true;
        }
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    function voteToAddAdmin(address candidate) external onlyAdmin {
        require(!admins[candidate], "Already admin");
        require(!addVotes[candidate][msg.sender], "Already voted");
        addVotes[candidate][msg.sender] = true;
        uint256 count = 0;
        for (uint256 i = 0; i < 100; i++) {
            if (addVotes[candidate][msg.sender]) count++;
        }
        if (count >= VOTE_THRESHOLD) {
            admins[candidate] = true;
            emit AdminAdded(candidate);
        }
    }

    function voteToRemoveAdmin(address admin) external onlyAdmin {
        require(admins[admin], "Not admin");
        require(!removeVotes[admin][msg.sender], "Already voted");
        removeVotes[admin][msg.sender] = true;
        uint256 count = 0;
        for (uint256 i = 0; i < 100; i++) {
            if (removeVotes[admin][msg.sender]) count++;
        }
        if (count >= VOTE_THRESHOLD) {
            admins[admin] = false;
            emit AdminRemoved(admin);
        }
    }
}
