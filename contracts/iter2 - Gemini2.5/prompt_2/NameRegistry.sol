// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) public userNames;
    mapping(string => bool) private nameTaken;

    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string newName);
    event NameRemoved(address indexed user, string name);

    function registerName(string memory _name) public {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(!nameTaken[_name], "Name is already taken.");
        require(bytes(userNames[msg.sender]).length == 0, "You have already registered a name. Use updateName instead.");

        userNames[msg.sender] = _name;
        nameTaken[_name] = true;
        emit NameRegistered(msg.sender, _name);
    }

    function updateName(string memory _newName) public {
        require(bytes(_newName).length > 0, "New name cannot be empty.");
        require(!nameTaken[_newName], "New name is already taken.");
        
        string memory oldName = userNames[msg.sender];
        require(bytes(oldName).length > 0, "No name registered to update.");

        nameTaken[oldName] = false;
        userNames[msg.sender] = _newName;
        nameTaken[_newName] = true;
        emit NameUpdated(msg.sender, _newName);
    }

    function removeName() public {
        string memory name = userNames[msg.sender];
        require(bytes(name).length > 0, "No name registered to remove.");

        delete userNames[msg.sender];
        nameTaken[name] = false;
        emit NameRemoved(msg.sender, name);
    }

    function getName(address _user) public view returns (string memory) {
        return userNames[_user];
    }
}
