// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;

    event NameRegistered(string indexed name, address indexed user);
    event NameUpdated(string indexed oldName, string indexed newName, address indexed user);
    event NameRemoved(string indexed name, address indexed user);

    function registerName(string calldata name) external {
        require(bytes(name).length > 0, "Name required");
        require(nameToAddress[name] == address(0), "Name taken");
        require(bytes(addressToName[msg.sender]).length == 0, "Already registered");
        nameToAddress[name] = msg.sender;
        addressToName[msg.sender] = name;
        emit NameRegistered(name, msg.sender);
    }

    function updateName(string calldata newName) external {
        require(bytes(newName).length > 0, "Name required");
        string storage oldName = addressToName[msg.sender];
        require(bytes(oldName).length > 0, "No name registered");
        require(nameToAddress[newName] == address(0), "Name taken");
        nameToAddress[newName] = msg.sender;
        nameToAddress[oldName] = address(0);
        addressToName[msg.sender] = newName;
        emit NameUpdated(oldName, newName, msg.sender);
    }

    function removeName() external {
        string storage name = addressToName[msg.sender];
        require(bytes(name).length > 0, "No name registered");
        nameToAddress[name] = address(0);
        addressToName[msg.sender] = "";
        emit NameRemoved(name, msg.sender);
    }

    function resolve(string calldata name) external view returns (address) {
        return nameToAddress[name];
    }

    function reverseResolve(address user) external view returns (string memory) {
        return addressToName[user];
    }
}
