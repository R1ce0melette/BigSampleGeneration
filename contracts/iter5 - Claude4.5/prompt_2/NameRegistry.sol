// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) public addressToName;
    mapping(string => address) public nameToAddress;
    mapping(address => bool) public isRegistered;
    
    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string oldName, string newName);
    event NameRemoved(address indexed user, string name);
    
    function registerName(string memory name) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(!isRegistered[msg.sender], "Address already has a registered name");
        require(nameToAddress[name] == address(0), "Name already taken");
        
        addressToName[msg.sender] = name;
        nameToAddress[name] = msg.sender;
        isRegistered[msg.sender] = true;
        
        emit NameRegistered(msg.sender, name);
    }
    
    function updateName(string memory newName) external {
        require(isRegistered[msg.sender], "No name registered for this address");
        require(bytes(newName).length > 0, "Name cannot be empty");
        require(nameToAddress[newName] == address(0), "Name already taken");
        
        string memory oldName = addressToName[msg.sender];
        
        delete nameToAddress[oldName];
        
        addressToName[msg.sender] = newName;
        nameToAddress[newName] = msg.sender;
        
        emit NameUpdated(msg.sender, oldName, newName);
    }
    
    function removeName() external {
        require(isRegistered[msg.sender], "No name registered for this address");
        
        string memory name = addressToName[msg.sender];
        
        delete nameToAddress[name];
        delete addressToName[msg.sender];
        delete isRegistered[msg.sender];
        
        emit NameRemoved(msg.sender, name);
    }
    
    function getNameByAddress(address user) external view returns (string memory) {
        return addressToName[user];
    }
    
    function getAddressByName(string memory name) external view returns (address) {
        return nameToAddress[name];
    }
}
