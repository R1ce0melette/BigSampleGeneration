// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) private names;
    mapping(string => address) private nameToAddress;

    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string newName);
    event NameRemoved(address indexed user);

    function registerName(string calldata name) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(nameToAddress[name] == address(0), "Name already taken");
        require(bytes(names[msg.sender]).length == 0, "Already registered");
        names[msg.sender] = name;
        nameToAddress[name] = msg.sender;
        emit NameRegistered(msg.sender, name);
    }

    function updateName(string calldata newName) external {
        require(bytes(newName).length > 0, "Name cannot be empty");
        require(nameToAddress[newName] == address(0), "Name already taken");
        string memory oldName = names[msg.sender];
        require(bytes(oldName).length > 0, "No name registered");
        delete nameToAddress[oldName];
        names[msg.sender] = newName;
        nameToAddress[newName] = msg.sender;
        emit NameUpdated(msg.sender, newName);
    }

    function removeName() external {
        string memory oldName = names[msg.sender];
        require(bytes(oldName).length > 0, "No name registered");
        delete nameToAddress[oldName];
        delete names[msg.sender];
        emit NameRemoved(msg.sender);
    }

    function getName(address user) external view returns (string memory) {
        return names[user];
    }

    function getAddress(string calldata name) external view returns (address) {
        return nameToAddress[name];
    }
}
