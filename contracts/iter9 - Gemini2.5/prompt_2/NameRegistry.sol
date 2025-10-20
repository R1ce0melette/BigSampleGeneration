// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) public names;

    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string newName);
    event NameRemoved(address indexed user);

    function registerName(string memory _name) public {
        require(bytes(names[msg.sender]).length == 0, "Name already registered for this address.");
        require(bytes(_name).length > 0, "Name cannot be empty.");
        names[msg.sender] = _name;
        emit NameRegistered(msg.sender, _name);
    }

    function updateName(string memory _newName) public {
        require(bytes(names[msg.sender]).length != 0, "No name registered for this address.");
        require(bytes(_newName).length > 0, "New name cannot be empty.");
        names[msg.sender] = _newName;
        emit NameUpdated(msg.sender, _newName);
    }

    function removeName() public {
        require(bytes(names[msg.sender]).length != 0, "No name registered for this address.");
        delete names[msg.sender];
        emit NameRemoved(msg.sender);
    }

    function getName(address _user) public view returns (string memory) {
        return names[_user];
    }
}
