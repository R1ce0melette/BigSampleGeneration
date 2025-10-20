// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) public userNames;
    mapping(string => address) public nameToAddress;

    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string oldName, string newName);
    event NameRemoved(address indexed user, string name);

    function registerName(string memory _name) public {
        require(bytes(userNames[msg.sender]).length == 0, "User already has a name registered.");
        require(nameToAddress[_name] == address(0), "Name is already taken.");
        require(bytes(_name).length > 0, "Name cannot be empty.");

        userNames[msg.sender] = _name;
        nameToAddress[_name] = msg.sender;
        emit NameRegistered(msg.sender, _name);
    }

    function updateName(string memory _newName) public {
        string memory oldName = userNames[msg.sender];
        require(bytes(oldName).length != 0, "No name registered for this user.");
        require(nameToAddress[_newName] == address(0), "New name is already taken.");
        require(bytes(_newName).length > 0, "Name cannot be empty.");

        // Clean up old name mapping
        delete nameToAddress[oldName];

        // Set new name
        userNames[msg.sender] = _newName;
        nameToAddress[_newName] = msg.sender;
        emit NameUpdated(msg.sender, oldName, _newName);
    }

    function removeName() public {
        string memory name = userNames[msg.sender];
        require(bytes(name).length != 0, "No name registered for this user.");

        delete nameToAddress[name];
        delete userNames[msg.sender];
        emit NameRemoved(msg.sender, name);
    }
}
