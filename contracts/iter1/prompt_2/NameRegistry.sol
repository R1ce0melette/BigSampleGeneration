// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) private names;
    mapping(string => address) private nameToAddress;

    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string newName);
    event NameRemoved(address indexed user, string oldName);

    function registerName(string calldata name) external {
        require(bytes(name).length > 0, "Name required");
        require(nameToAddress[name] == address(0), "Name taken");
        require(bytes(names[msg.sender]).length == 0, "Already registered");
        names[msg.sender] = name;
        nameToAddress[name] = msg.sender;
        emit NameRegistered(msg.sender, name);
    }

    function updateName(string calldata newName) external {
        require(bytes(newName).length > 0, "Name required");
        require(nameToAddress[newName] == address(0), "Name taken");
        string memory oldName = names[msg.sender];
        require(bytes(oldName).length > 0, "Not registered");
        nameToAddress[oldName] = address(0);
        names[msg.sender] = newName;
        nameToAddress[newName] = msg.sender;
        emit NameUpdated(msg.sender, newName);
    }

    function removeName() external {
        string memory oldName = names[msg.sender];
        require(bytes(oldName).length > 0, "Not registered");
        nameToAddress[oldName] = address(0);
        names[msg.sender] = "";
        emit NameRemoved(msg.sender, oldName);
    }

    function getName(address user) external view returns (string memory) {
        return names[user];
    }

    function getAddress(string calldata name) external view returns (address) {
        return nameToAddress[name];
    }
}
