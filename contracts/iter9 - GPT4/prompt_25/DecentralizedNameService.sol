// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;

    event NameRegistered(string indexed name, address indexed user);
    event NameUpdated(string indexed name, address indexed user);
    event NameRemoved(string indexed name, address indexed user);

    function registerName(string calldata name) external {
        require(nameToAddress[name] == address(0), "Name taken");
        require(bytes(addressToName[msg.sender]).length == 0, "Already registered");
        nameToAddress[name] = msg.sender;
        addressToName[msg.sender] = name;
        emit NameRegistered(name, msg.sender);
    }

    function updateName(string calldata newName) external {
        require(bytes(addressToName[msg.sender]).length != 0, "No name registered");
        require(nameToAddress[newName] == address(0), "Name taken");
        string memory oldName = addressToName[msg.sender];
        delete nameToAddress[oldName];
        nameToAddress[newName] = msg.sender;
        addressToName[msg.sender] = newName;
        emit NameUpdated(newName, msg.sender);
    }

    function removeName() external {
        require(bytes(addressToName[msg.sender]).length != 0, "No name registered");
        string memory name = addressToName[msg.sender];
        delete nameToAddress[name];
        delete addressToName[msg.sender];
        emit NameRemoved(name, msg.sender);
    }

    function resolve(string calldata name) external view returns (address) {
        return nameToAddress[name];
    }

    function reverseResolve(address user) external view returns (string memory) {
        return addressToName[user];
    }
}
