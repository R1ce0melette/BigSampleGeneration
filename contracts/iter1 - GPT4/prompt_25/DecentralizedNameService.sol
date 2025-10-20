// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;

    event NameRegistered(string name, address indexed user);
    event NameUpdated(string oldName, string newName, address indexed user);
    event NameRemoved(string name, address indexed user);

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
        require(nameToAddress[newName] == address(0), "Name taken");
        string memory oldName = addressToName[msg.sender];
        require(bytes(oldName).length > 0, "Not registered");
        nameToAddress[oldName] = address(0);
        nameToAddress[newName] = msg.sender;
        addressToName[msg.sender] = newName;
        emit NameUpdated(oldName, newName, msg.sender);
    }

    function removeName() external {
        string memory name = addressToName[msg.sender];
        require(bytes(name).length > 0, "Not registered");
        nameToAddress[name] = address(0);
        addressToName[msg.sender] = "";
        emit NameRemoved(name, msg.sender);
    }

    function resolveName(string calldata name) external view returns (address) {
        return nameToAddress[name];
    }

    function resolveAddress(address user) external view returns (string memory) {
        return addressToName[user];
    }
}
