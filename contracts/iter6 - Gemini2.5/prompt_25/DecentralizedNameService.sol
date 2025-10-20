// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(string => address) public nameOwner;

    event NameRegistered(string name, address indexed owner);
    event NameTransferred(string name, address indexed from, address indexed to);
    event AddressUpdated(string name, address newAddress);

    function registerName(string memory _name) public {
        require(nameOwner[_name] == address(0), "Name is already taken.");
        
        nameOwner[_name] = msg.sender;
        nameToAddress[_name] = msg.sender; // Initially, the name points to the owner's address

        emit NameRegistered(_name, msg.sender);
    }

    function updateAddress(string memory _name, address _newAddress) public {
        require(nameOwner[_name] == msg.sender, "Only the owner can update the address.");
        
        nameToAddress[_name] = _newAddress;
        emit AddressUpdated(_name, _newAddress);
    }

    function transferName(string memory _name, address _newOwner) public {
        require(nameOwner[_name] == msg.sender, "Only the owner can transfer the name.");
        require(_newOwner != address(0), "Cannot transfer to the zero address.");

        address oldOwner = msg.sender;
        nameOwner[_name] = _newOwner;
        
        // Optional: decide if the resolved address should also change upon transfer
        // For now, we leave it as is, the new owner can update it.

        emit NameTransferred(_name, oldOwner, _newOwner);
    }

    function resolveName(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }
}
