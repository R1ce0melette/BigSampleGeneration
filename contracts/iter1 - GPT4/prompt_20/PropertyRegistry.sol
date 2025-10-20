// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    struct Property {
        uint256 id;
        string details;
        address owner;
    }

    uint256 public nextPropertyId;
    mapping(uint256 => Property) public properties;

    event PropertyRegistered(uint256 indexed id, address indexed owner, string details);
    event PropertyTransferred(uint256 indexed id, address indexed from, address indexed to);

    function registerProperty(string calldata details) external {
        require(bytes(details).length > 0, "Details required");
        properties[nextPropertyId] = Property(nextPropertyId, details, msg.sender);
        emit PropertyRegistered(nextPropertyId, msg.sender, details);
        nextPropertyId++;
    }

    function transferProperty(uint256 propertyId, address newOwner) external {
        Property storage prop = properties[propertyId];
        require(msg.sender == prop.owner, "Not property owner");
        require(newOwner != address(0), "Invalid new owner");
        address oldOwner = prop.owner;
        prop.owner = newOwner;
        emit PropertyTransferred(propertyId, oldOwner, newOwner);
    }

    function getProperty(uint256 propertyId) external view returns (uint256, string memory, address) {
        Property storage prop = properties[propertyId];
        return (prop.id, prop.details, prop.owner);
    }
}
