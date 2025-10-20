// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) private names;
    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string newName);
    event NameRemoved(address indexed user);

    function registerName(string calldata name) external {
        require(bytes(names[msg.sender]).length == 0, "Name already registered");
        names[msg.sender] = name;
        emit NameRegistered(msg.sender, name);
    }

    function updateName(string calldata newName) external {
        require(bytes(names[msg.sender]).length != 0, "No name registered");
        names[msg.sender] = newName;
        emit NameUpdated(msg.sender, newName);
    }

    function removeName() external {
        require(bytes(names[msg.sender]).length != 0, "No name registered");
        delete names[msg.sender];
        emit NameRemoved(msg.sender);
    }

    function getName(address user) external view returns (string memory) {
        return names[user];
    }
}
