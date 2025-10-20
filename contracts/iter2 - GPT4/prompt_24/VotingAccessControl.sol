// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    mapping(address => bool) public isAdmin;
    address[] public admins;
    mapping(address => mapping(address => bool)) public addVotes;
    mapping(address => mapping(address => bool)) public removeVotes;
    uint256 public voteThreshold;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);

    constructor(address[] memory initialAdmins, uint256 _voteThreshold) {
        require(initialAdmins.length > 0, "No initial admins");
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            isAdmin[initialAdmins[i]] = true;
            admins.push(initialAdmins[i]);
        }
        voteThreshold = _voteThreshold;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    function voteAddAdmin(address candidate) external onlyAdmin {
        require(!isAdmin[candidate], "Already admin");
        require(!addVotes[candidate][msg.sender], "Already voted");
        addVotes[candidate][msg.sender] = true;
        uint256 count = 0;
        for (uint256 i = 0; i < admins.length; i++) {
            if (addVotes[candidate][admins[i]]) count++;
        }
        if (count >= voteThreshold) {
            isAdmin[candidate] = true;
            admins.push(candidate);
            emit AdminAdded(candidate);
            // Reset votes
            for (uint256 i = 0; i < admins.length; i++) {
                addVotes[candidate][admins[i]] = false;
            }
        }
    }

    function voteRemoveAdmin(address admin) external onlyAdmin {
        require(isAdmin[admin], "Not admin");
        require(admin != msg.sender, "Cannot remove self");
        require(!removeVotes[admin][msg.sender], "Already voted");
        removeVotes[admin][msg.sender] = true;
        uint256 count = 0;
        for (uint256 i = 0; i < admins.length; i++) {
            if (removeVotes[admin][admins[i]]) count++;
        }
        if (count >= voteThreshold) {
            isAdmin[admin] = false;
            // Remove from admins array
            for (uint256 i = 0; i < admins.length; i++) {
                if (admins[i] == admin) {
                    admins[i] = admins[admins.length - 1];
                    admins.pop();
                    break;
                }
            }
            emit AdminRemoved(admin);
            // Reset votes
            for (uint256 i = 0; i < admins.length; i++) {
                removeVotes[admin][admins[i]] = false;
            }
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }
}
