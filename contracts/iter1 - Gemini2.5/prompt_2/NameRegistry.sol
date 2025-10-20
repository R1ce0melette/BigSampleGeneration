// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) public names;

    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string newName);
    event NameRemoved(address indexed user);

    function registerName(string memory name) public {
        require(bytes(names[msg.sender]).length == 0, "Name already registered");
        names[msg.sender] = name;
        emit NameRegistered(msg.sender, name);
    }

    function updateName(string memory newName) public {
        require(bytes(names[msg.sender]).length > 0, "No name registered to update");
        names[msg.sender] = newName;
        emit NameUpdated(msg.sender, newName);
    }

    function removeName() public {
        require(bytes(names[msg.sender]).length > 0, "No name registered to remove");
        delete names[msg.sender];
        emit NameRemoved(msg.sender);
    }

    function getName(address user) public view returns (string memory) {
        return names[user];
    }
}
