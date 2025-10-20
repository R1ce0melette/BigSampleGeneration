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

    event PropertyRegistered(uint256 id, address indexed owner, string details);
    event PropertyTransferred(uint256 id, address indexed from, address indexed to);

    function registerProperty(string calldata details) external {
        properties[nextPropertyId] = Property({
            id: nextPropertyId,
            owner: msg.sender,
            details: details
        });
        emit PropertyRegistered(nextPropertyId, msg.sender, details);
        nextPropertyId++;
    }

    function transferProperty(uint256 propertyId, address to) external {
        require(propertyId < nextPropertyId, "Property does not exist");
        Property storage prop = properties[propertyId];
        require(msg.sender == prop.owner, "Not property owner");
        address from = prop.owner;
        prop.owner = to;
        emit PropertyTransferred(propertyId, from, to);
    }

    function verifyOwnership(uint256 propertyId, address user) external view returns (bool) {
        require(propertyId < nextPropertyId, "Property does not exist");
        return properties[propertyId].owner == user;
    }
}
