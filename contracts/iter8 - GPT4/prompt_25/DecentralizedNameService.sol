// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    mapping(string => address) public nameToAddress;
    mapping(string => address) public nameOwner;

    event NameRegistered(string indexed name, address indexed owner, address indexed mappedAddress);
    event NameUpdated(string indexed name, address indexed newAddress);
    event NameTransferred(string indexed name, address indexed oldOwner, address indexed newOwner);

    function registerName(string calldata name, address mappedAddress) external {
        require(bytes(name).length > 0, "Name required");
        require(mappedAddress != address(0), "Invalid address");
        require(nameOwner[name] == address(0), "Name taken");
        nameToAddress[name] = mappedAddress;
        nameOwner[name] = msg.sender;
        emit NameRegistered(name, msg.sender, mappedAddress);
    }

    function updateName(string calldata name, address newAddress) external {
        require(nameOwner[name] == msg.sender, "Not owner");
        require(newAddress != address(0), "Invalid address");
        nameToAddress[name] = newAddress;
        emit NameUpdated(name, newAddress);
    }

    function transferName(string calldata name, address newOwner) external {
        require(nameOwner[name] == msg.sender, "Not owner");
        require(newOwner != address(0), "Invalid address");
        address oldOwner = nameOwner[name];
        nameOwner[name] = newOwner;
        emit NameTransferred(name, oldOwner, newOwner);
    }

    function resolve(string calldata name) external view returns (address) {
        return nameToAddress[name];
    }
}
