// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;

    event NameRegistered(string name, address indexed owner);
    event NameTransferred(string name, address indexed from, address indexed to);

    function registerName(string memory _name) public {
        require(nameToAddress[_name] == address(0), "Name is already taken.");
        require(bytes(addressToName[msg.sender]).length == 0, "Address already has a name registered.");

        nameToAddress[_name] = msg.sender;
        addressToName[msg.sender] = _name;

        emit NameRegistered(_name, msg.sender);
    }

    function transferName(address _newOwner) public {
        string memory name = addressToName[msg.sender];
        require(bytes(name).length > 0, "You do not own a name to transfer.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        require(bytes(addressToName[_newOwner]).length == 0, "New owner already has a name registered.");

        // Clear old owner's records
        delete addressToName[msg.sender];
        
        // Set new owner's records
        nameToAddress[name] = _newOwner;
        addressToName[_newOwner] = name;

        emit NameTransferred(name, msg.sender, _newOwner);
    }

    function resolveName(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }

    function reverseLookup(address _owner) public view returns (string memory) {
        return addressToName[_owner];
    }
}
