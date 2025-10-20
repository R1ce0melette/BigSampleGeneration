// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) public addressToName;
    mapping(string => address) public nameToAddress;
    
    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string oldName, string newName);
    event NameRemoved(address indexed user, string name);
    
    function registerName(string memory _name) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(addressToName[msg.sender]).length == 0, "Name already registered for this address");
        require(nameToAddress[_name] == address(0), "Name already taken");
        
        addressToName[msg.sender] = _name;
        nameToAddress[_name] = msg.sender;
        
        emit NameRegistered(msg.sender, _name);
    }
    
    function updateName(string memory _newName) external {
        require(bytes(_newName).length > 0, "Name cannot be empty");
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
        require(nameToAddress[_newName] == address(0), "Name already taken");
        
        string memory oldName = addressToName[msg.sender];
        
        delete nameToAddress[oldName];
        addressToName[msg.sender] = _newName;
        nameToAddress[_newName] = msg.sender;
        
        emit NameUpdated(msg.sender, oldName, _newName);
    }
    
    function removeName() external {
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
        
        string memory name = addressToName[msg.sender];
        
        delete nameToAddress[name];
        delete addressToName[msg.sender];
        
        emit NameRemoved(msg.sender, name);
    }
    
    function getNameByAddress(address _address) external view returns (string memory) {
        return addressToName[_address];
    }
    
    function getAddressByName(string memory _name) external view returns (address) {
        return nameToAddress[_name];
    }
}
