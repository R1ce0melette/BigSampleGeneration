// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameService {
    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;

    event NameRegistered(string name, address indexed owner);
    event NameTransferred(string name, address indexed from, address indexed to);

    function register(string memory _name) public {
        require(nameToAddress[_name] == address(0), "Name is already taken.");
        require(bytes(addressToName[msg.sender]).length == 0, "Address already has a name registered.");
        
        nameToAddress[_name] = msg.sender;
        addressToName[msg.sender] = _name;
        
        emit NameRegistered(_name, msg.sender);
    }

    function transferName(address _to) public {
        string memory name = addressToName[msg.sender];
        require(bytes(name).length > 0, "You do not own a name.");
        require(_to != address(0), "Cannot transfer to the zero address.");
        require(bytes(addressToName[_to]).length == 0, "Recipient already has a name registered.");

        // Clear old owner's mappings
        delete addressToName[msg.sender];
        
        // Set new owner's mappings
        nameToAddress[name] = _to;
        addressToName[_to] = name;

        emit NameTransferred(name, msg.sender, _to);
    }

    function resolve(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }

    function reverseLookup(address _addr) public view returns (string memory) {
        return addressToName[_addr];
    }
}
