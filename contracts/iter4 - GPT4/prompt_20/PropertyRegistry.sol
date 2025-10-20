// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public owner;
    uint256 public nextPropertyId;

    struct Property {
        address currentOwner;
        string details;
    }

    mapping(uint256 => Property) public properties;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyPropertyOwner(uint256 propertyId) {
        require(properties[propertyId].currentOwner == msg.sender, "Not property owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerProperty(address propertyOwner, string calldata details) external onlyOwner {
        properties[nextPropertyId] = Property(propertyOwner, details);
        nextPropertyId++;
    }

    function transferProperty(uint256 propertyId, address newOwner) external onlyPropertyOwner(propertyId) {
        properties[propertyId].currentOwner = newOwner;
    }

    function verifyOwnership(uint256 propertyId, address user) external view returns (bool) {
        return properties[propertyId].currentOwner == user;
    }
}
