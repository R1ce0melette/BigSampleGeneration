// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public owner;

    struct Property {
        uint256 id;
        string details;
        address owner;
    }

    mapping(uint256 => Property) public properties;
    uint256 public propertyCount;

    event PropertyRegistered(uint256 id, string details, address indexed owner);
    event PropertyTransferred(uint256 id, address indexed from, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerProperty(string memory _details, address _initialOwner) public onlyOwner {
        propertyCount++;
        properties[propertyCount] = Property(propertyCount, _details, _initialOwner);
        emit PropertyRegistered(propertyCount, _details, _initialOwner);
    }

    function transferProperty(uint256 _id, address _newOwner) public {
        require(_id > 0 && _id <= propertyCount, "Property does not exist.");
        Property storage prop = properties[_id];
        require(msg.sender == prop.owner, "Only the current owner can transfer the property.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address oldOwner = prop.owner;
        prop.owner = _newOwner;
        emit PropertyTransferred(_id, oldOwner, _newOwner);
    }

    function verifyOwnership(uint256 _id) public view returns (address) {
        require(_id > 0 && _id <= propertyCount, "Property does not exist.");
        return properties[_id].owner;
    }

    function getPropertyDetails(uint256 _id) public view returns (string memory) {
        require(_id > 0 && _id <= propertyCount, "Property does not exist.");
        return properties[_id].details;
    }
}
