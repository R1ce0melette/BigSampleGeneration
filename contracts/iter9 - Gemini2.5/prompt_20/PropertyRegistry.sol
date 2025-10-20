// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public contractOwner;

    struct Property {
        uint id;
        string details;
        address owner;
        bool isRegistered;
    }

    mapping(uint => Property) public properties;
    uint public propertyCount;

    event PropertyRegistered(uint id, address indexed owner);
    event PropertyTransferred(uint id, address indexed from, address indexed to);

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function registerProperty(string memory _details, address _initialOwner) public onlyContractOwner {
        propertyCount++;
        properties[propertyCount] = Property(propertyCount, _details, _initialOwner, true);
        emit PropertyRegistered(propertyCount, _initialOwner);
    }

    function transferProperty(uint _propertyId, address _newOwner) public {
        Property storage prop = properties[_propertyId];
        require(prop.isRegistered, "Property is not registered.");
        require(msg.sender == prop.owner, "Only the current owner can transfer the property.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address oldOwner = prop.owner;
        prop.owner = _newOwner;
        emit PropertyTransferred(_propertyId, oldOwner, _newOwner);
    }

    function getPropertyOwner(uint _propertyId) public view returns (address) {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        return properties[_propertyId].owner;
    }

    function getPropertyDetails(uint _propertyId) public view returns (string memory) {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        return properties[_propertyId].details;
    }
}
