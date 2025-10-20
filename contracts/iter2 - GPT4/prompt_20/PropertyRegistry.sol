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

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner");
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
        properties[nextPropertyId] = Property(nextPropertyId, propertyOwner, details);
        ownerProperties[propertyOwner].push(nextPropertyId);
        nextPropertyId++;
    }

    function transferProperty(uint256 propertyId, address newOwner) external onlyPropertyOwner(propertyId) {
        address prevOwner = properties[propertyId].currentOwner;
        properties[propertyId].currentOwner = newOwner;
        ownerProperties[newOwner].push(propertyId);
        // Remove from previous owner's list (not gas efficient, but simple)
        uint256[] storage prevList = ownerProperties[prevOwner];
        for (uint256 i = 0; i < prevList.length; i++) {
            if (prevList[i] == propertyId) {
                prevList[i] = prevList[prevList.length - 1];
                prevList.pop();
                break;
            }
        }
    }

    function verifyOwnership(uint256 propertyId, address user) external view returns (bool) {
        return properties[propertyId].currentOwner == user;
    }
}
