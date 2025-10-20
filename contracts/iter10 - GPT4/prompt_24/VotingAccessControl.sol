// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    mapping(address => bool) public isAdmin;
    address[] public admins;
    mapping(address => mapping(address => bool)) public addVotes;
    mapping(address => mapping(address => bool)) public removeVotes;
    uint256 public constant VOTE_THRESHOLD = 2;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length > 0, "At least one admin");
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            isAdmin[initialAdmins[i]] = true;
            admins.push(initialAdmins[i]);
        }
    }

    function voteAddAdmin(address candidate) external onlyAdmin {
        require(!isAdmin[candidate], "Already admin");
        require(!addVotes[candidate][msg.sender], "Already voted");
        addVotes[candidate][msg.sender] = true;
        uint256 votes = countAddVotes(candidate);
        if (votes >= VOTE_THRESHOLD) {
            isAdmin[candidate] = true;
            admins.push(candidate);
            clearAddVotes(candidate);
            emit AdminAdded(candidate);
        }
    }

    function voteRemoveAdmin(address admin) external onlyAdmin {
        require(isAdmin[admin], "Not an admin");
        require(admin != msg.sender, "Cannot remove self");
        require(!removeVotes[admin][msg.sender], "Already voted");
        removeVotes[admin][msg.sender] = true;
        uint256 votes = countRemoveVotes(admin);
        if (votes >= VOTE_THRESHOLD) {
            isAdmin[admin] = false;
            removeAdminFromList(admin);
            clearRemoveVotes(admin);
            emit AdminRemoved(admin);
        }
    }

    function countAddVotes(address candidate) public view returns (uint256 count) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (addVotes[candidate][admins[i]]) count++;
        }
    }

    function countRemoveVotes(address admin) public view returns (uint256 count) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (removeVotes[admin][admins[i]]) count++;
        }
    }

    function clearAddVotes(address candidate) internal {
        for (uint256 i = 0; i < admins.length; i++) {
            addVotes[candidate][admins[i]] = false;
        }
    }

    function clearRemoveVotes(address admin) internal {
        for (uint256 i = 0; i < admins.length; i++) {
            removeVotes[admin][admins[i]] = false;
        }
    }

    function removeAdminFromList(address admin) internal {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == admin) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                break;
            }
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }
}
