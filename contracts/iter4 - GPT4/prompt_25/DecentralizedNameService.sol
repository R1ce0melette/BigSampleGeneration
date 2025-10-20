// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;

    function register(string calldata name) external {
        require(nameToAddress[name] == address(0), "Name taken");
        require(bytes(addressToName[msg.sender]).length == 0, "Already registered");
        nameToAddress[name] = msg.sender;
        addressToName[msg.sender] = name;
    }

    function updateName(string calldata newName) external {
        require(bytes(addressToName[msg.sender]).length != 0, "Not registered");
        require(nameToAddress[newName] == address(0), "Name taken");
        string memory oldName = addressToName[msg.sender];
        delete nameToAddress[oldName];
        nameToAddress[newName] = msg.sender;
        addressToName[msg.sender] = newName;
    }

    function remove() external {
        require(bytes(addressToName[msg.sender]).length != 0, "Not registered");
        string memory oldName = addressToName[msg.sender];
        delete nameToAddress[oldName];
        delete addressToName[msg.sender];
    }
}
