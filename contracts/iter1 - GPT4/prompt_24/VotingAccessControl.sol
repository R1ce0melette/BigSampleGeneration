// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAccessControl {
    address[] public admins;
    mapping(address => bool) public isAdmin;
    mapping(address => mapping(address => bool)) public votes;
    mapping(address => uint256) public voteCounts;
    uint256 public minVotes = 2;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);
    event Voted(address indexed voter, address indexed candidate, bool add);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    constructor() {
        admins.push(msg.sender);
        isAdmin[msg.sender] = true;
    }

    function voteToAddAdmin(address candidate) external onlyAdmin {
        require(!isAdmin[candidate], "Already admin");
        require(!votes[msg.sender][candidate], "Already voted");
        votes[msg.sender][candidate] = true;
        voteCounts[candidate] += 1;
        emit Voted(msg.sender, candidate, true);
        if (voteCounts[candidate] >= minVotes) {
            admins.push(candidate);
            isAdmin[candidate] = true;
            voteCounts[candidate] = 0;
            emit AdminAdded(candidate);
        }
    }

    function voteToRemoveAdmin(address admin) external onlyAdmin {
        require(isAdmin[admin], "Not admin");
        require(admin != msg.sender, "Cannot remove self");
        require(!votes[msg.sender][admin], "Already voted");
        votes[msg.sender][admin] = true;
        voteCounts[admin] += 1;
        emit Voted(msg.sender, admin, false);
        if (voteCounts[admin] >= minVotes) {
            isAdmin[admin] = false;
            for (uint i = 0; i < admins.length; i++) {
                if (admins[i] == admin) {
                    admins[i] = admins[admins.length - 1];
                    admins.pop();
                    break;
                }
            }
            voteCounts[admin] = 0;
            emit AdminRemoved(admin);
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }
}
