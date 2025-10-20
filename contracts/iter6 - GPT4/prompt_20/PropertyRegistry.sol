// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    struct Property {
        uint256 id;
        address owner;
        string details;
    }

    uint256 public nextPropertyId;
    mapping(uint256 => Property) public properties;
    mapping(uint256 => bool) public exists;

    event PropertyRegistered(uint256 indexed id, address indexed owner, string details);
    event PropertyTransferred(uint256 indexed id, address indexed from, address indexed to);

    function registerProperty(string calldata details) external {
        properties[nextPropertyId] = Property({
            id: nextPropertyId,
            owner: msg.sender,
            details: details
        });
        exists[nextPropertyId] = true;
        emit PropertyRegistered(nextPropertyId, msg.sender, details);
        nextPropertyId++;
    }

    function transferProperty(uint256 id, address to) external {
        require(exists[id], "Property does not exist");
        require(properties[id].owner == msg.sender, "Not property owner");
        address from = msg.sender;
        properties[id].owner = to;
        emit PropertyTransferred(id, from, to);
    }

    function verifyOwnership(uint256 id, address user) external view returns (bool) {
        require(exists[id], "Property does not exist");
        return properties[id].owner == user;
    }
}
