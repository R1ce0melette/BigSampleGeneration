// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public owner;

    struct Property {
        uint256 id;
        string details; // e.g., address, size, etc.
        address currentOwner;
    }

    mapping(uint256 => Property) public properties;
    uint256 public propertyCounter;

    event PropertyRegistered(uint256 indexed id, address indexed owner);
    event PropertyTransferred(uint256 indexed id, address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    function registerProperty(string memory _details, address _initialOwner) public onlyOwner {
        require(_initialOwner != address(0), "Owner cannot be the zero address.");
        propertyCounter++;
        properties[propertyCounter] = Property(propertyCounter, _details, _initialOwner);
        emit PropertyRegistered(propertyCounter, _initialOwner);
    }

    function transferProperty(uint256 _propertyId, address _newOwner) public {
        require(_propertyId > 0 && _propertyId <= propertyCounter, "Property does not exist.");
        Property storage prop = properties[_propertyId];
        require(msg.sender == prop.currentOwner, "Only the current owner can transfer the property.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address previousOwner = prop.currentOwner;
        prop.currentOwner = _newOwner;
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner);
    }

    function verifyOwnership(uint256 _propertyId) public view returns (address) {
        require(_propertyId > 0 && _propertyId <= propertyCounter, "Property does not exist.");
        return properties[_propertyId].currentOwner;
    }

    function getPropertyDetails(uint256 _propertyId) public view returns (uint256, string memory, address) {
        require(_propertyId > 0 && _propertyId <= propertyCounter, "Property does not exist.");
        Property storage prop = properties[_propertyId];
        return (prop.id, prop.details, prop.currentOwner);
    }
}
