// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public owner;

    struct Property {
        uint256 id;
        address owner;
        string details; // e.g., address, size, etc.
    }

    mapping(uint256 => Property) public properties;
    uint256 public propertyCounter;

    event PropertyRegistered(uint256 indexed id, address indexed owner, string details);
    event PropertyTransferred(uint256 indexed id, address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    function registerProperty(address _propertyOwner, string memory _details) public onlyOwner {
        propertyCounter++;
        properties[propertyCounter] = Property(propertyCounter, _propertyOwner, _details);
        emit PropertyRegistered(propertyCounter, _propertyOwner, _details);
    }

    function transferProperty(uint256 _propertyId, address _newOwner) public {
        require(_propertyId > 0 && _propertyId <= propertyCounter, "Property does not exist.");
        Property storage prop = properties[_propertyId];
        require(prop.owner == msg.sender || owner == msg.sender, "Only property owner or contract owner can transfer.");
        
        address oldOwner = prop.owner;
        prop.owner = _newOwner;
        
        emit PropertyTransferred(_propertyId, oldOwner, _newOwner);
    }

    function verifyOwnership(uint256 _propertyId) public view returns (address) {
        require(_propertyId > 0 && _propertyId <= propertyCounter, "Property does not exist.");
        return properties[_propertyId].owner;
    }
}
