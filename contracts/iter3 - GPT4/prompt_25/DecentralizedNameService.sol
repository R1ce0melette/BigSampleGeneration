// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;

    event NameRegistered(string name, address indexed owner);
    event NameRemoved(string name, address indexed owner);

    function registerName(string calldata name) external {
        require(nameToAddress[name] == address(0), "Name taken");
        require(bytes(addressToName[msg.sender]).length == 0, "Already registered");
        nameToAddress[name] = msg.sender;
        addressToName[msg.sender] = name;
        emit NameRegistered(name, msg.sender);
    }

    function removeName() external {
        string storage name = addressToName[msg.sender];
        require(bytes(name).length != 0, "No name registered");
        nameToAddress[name] = address(0);
        emit NameRemoved(name, msg.sender);
        delete addressToName[msg.sender];
    }

    function resolve(string calldata name) external view returns (address) {
        return nameToAddress[name];
    }

    function reverse(address user) external view returns (string memory) {
        return addressToName[user];
    }
}
