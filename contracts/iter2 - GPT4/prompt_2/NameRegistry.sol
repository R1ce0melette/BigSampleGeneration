// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    mapping(address => string) public names;

    function registerName(string calldata name) external {
        names[msg.sender] = name;
    }

    function updateName(string calldata newName) external {
        require(bytes(names[msg.sender]).length != 0, "Name not registered");
        names[msg.sender] = newName;
    }

    function removeName() external {
        require(bytes(names[msg.sender]).length != 0, "Name not registered");
        delete names[msg.sender];
    }
}
