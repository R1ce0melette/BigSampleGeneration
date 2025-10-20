// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public owner;
    uint256 public propertyCount;

    struct Property {
        uint256 id;
        string description;
        address currentOwner;
    }

    mapping(uint256 => Property) public properties;
    mapping(uint256 => address) public propertyToOwner;

    event PropertyRegistered(uint256 indexed id, address indexed owner, string description);
    event PropertyTransferred(uint256 indexed id, address indexed from, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyPropertyOwner(uint256 id) {
        require(propertyToOwner[id] == msg.sender, "Not property owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerProperty(string calldata description) external onlyOwner {
        require(bytes(description).length > 0, "Description required");
        propertyCount++;
        properties[propertyCount] = Property(propertyCount, description, owner);
        propertyToOwner[propertyCount] = owner;
        emit PropertyRegistered(propertyCount, owner, description);
    }

    function transferProperty(uint256 id, address to) external onlyPropertyOwner(id) {
        require(to != address(0), "Invalid address");
        address from = propertyToOwner[id];
        propertyToOwner[id] = to;
        properties[id].currentOwner = to;
        emit PropertyTransferred(id, from, to);
    }

    function verifyOwnership(uint256 id, address user) external view returns (bool) {
        return propertyToOwner[id] == user;
    }
}
