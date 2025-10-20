// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PropertyRegistry is Ownable {
    struct Property {
        uint256 id;
        string details; // e.g., address, size, type
        address owner;
    }

    // Mapping from property ID to Property struct
    mapping(uint256 => Property) public properties;
    // Keep track of the total number of properties registered
    uint256 public propertyCount;

    event PropertyRegistered(uint256 indexed propertyId, address indexed owner, string details);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Registers a new property to a specified owner. Only the contract owner can do this.
     * @param _owner The address of the new property owner.
     * @param _details A string containing details about the property.
     */
    function registerProperty(address _owner, string memory _details) public onlyOwner {
        require(_owner != address(0), "Owner address cannot be zero.");
        require(bytes(_details).length > 0, "Property details cannot be empty.");

        propertyCount++;
        properties[propertyCount] = Property(propertyCount, _details, _owner);

        emit PropertyRegistered(propertyCount, _owner, _details);
    }

    /**
     * @dev Transfers a property from its current owner to a new owner.
     *      Only the current owner of the property can initiate a transfer.
     * @param _propertyId The ID of the property to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferProperty(uint256 _propertyId, address _newOwner) public {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist.");
        require(_newOwner != address(0), "New owner address cannot be zero.");
        
        Property storage prop = properties[_propertyId];
        require(prop.owner == msg.sender, "Only the current owner can transfer the property.");
        
        address oldOwner = prop.owner;
        prop.owner = _newOwner;

        emit PropertyTransferred(_propertyId, oldOwner, _newOwner);
    }

    /**
     * @dev Verifies the owner of a specific property.
     * @param _propertyId The ID of the property to verify.
     * @return The address of the property's owner.
     */
    function verifyOwnership(uint256 _propertyId) public view returns (address) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist.");
        return properties[_propertyId].owner;
    }

    /**
     * @dev Retrieves the details of a specific property.
     * @param _propertyId The ID of the property.
     * @return The property ID, its details, and the owner's address.
     */
    function getPropertyDetails(uint256 _propertyId) public view returns (uint256, string memory, address) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist.");
        Property storage prop = properties[_propertyId];
        return (prop.id, prop.details, prop.owner);
    }
}
