// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public owner;
    uint256 public nextPropertyId;

    struct Property {
        uint256 id;
        address currentOwner;
        string details;
    }

    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties;

    event PropertyRegistered(uint256 indexed id, address indexed owner, string details);
    event PropertyTransferred(uint256 indexed id, address indexed from, address indexed to);

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

    function registerProperty(string calldata details) external onlyOwner {
        require(bytes(details).length > 0, "Details required");
        properties[nextPropertyId] = Property({
            id: nextPropertyId,
            currentOwner: owner,
            details: details
        });
        ownerProperties[owner].push(nextPropertyId);
        emit PropertyRegistered(nextPropertyId, owner, details);
        nextPropertyId++;
    }

    function transferProperty(uint256 propertyId, address to) external onlyPropertyOwner(propertyId) {
        require(to != address(0), "Invalid address");
        address from = properties[propertyId].currentOwner;
        properties[propertyId].currentOwner = to;
        ownerProperties[to].push(propertyId);
        emit PropertyTransferred(propertyId, from, to);
    }

    function verifyOwnership(uint256 propertyId, address user) external view returns (bool) {
        return properties[propertyId].currentOwner == user;
    }

    function getProperties(address user) external view returns (uint256[] memory) {
        return ownerProperties[user];
    }
}
