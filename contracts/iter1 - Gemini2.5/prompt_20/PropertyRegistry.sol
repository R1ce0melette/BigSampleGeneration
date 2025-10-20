// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public contractOwner;

    struct Property {
        address owner;
        string details; // e.g., physical address, lot number
        bool isRegistered;
    }

    mapping(uint256 => Property) public properties;
    uint256 public propertyCount;

    event PropertyRegistered(uint256 indexed propertyId, address indexed owner, string details);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to);

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function registerProperty(address _owner, string calldata _details) public onlyContractOwner returns (uint256) {
        uint256 newPropertyId = propertyCount;
        properties[newPropertyId] = Property({
            owner: _owner,
            details: _details,
            isRegistered: true
        });
        propertyCount++;
        emit PropertyRegistered(newPropertyId, _owner, _details);
        return newPropertyId;
    }

    function transferProperty(uint256 _propertyId, address _to) public {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        require(properties[_propertyId].owner == msg.sender, "Only the current property owner can transfer ownership.");
        require(_to != address(0), "Cannot transfer to the zero address.");

        address from = properties[_propertyId].owner;
        properties[_propertyId].owner = _to;

        emit PropertyTransferred(_propertyId, from, _to);
    }

    function getPropertyOwner(uint256 _propertyId) public view returns (address) {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        return properties[_propertyId].owner;
    }
    
    function getPropertyDetails(uint256 _propertyId) public view returns (string memory) {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        return properties[_propertyId].details;
    }
}
