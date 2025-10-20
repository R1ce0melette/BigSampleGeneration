// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PropertyRegistry
 * @dev A contract for registering and managing ownership of properties.
 * The contract owner is responsible for initially registering properties.
 */
contract PropertyRegistry {
    address public owner;
    uint256 private _propertyIdCounter;

    struct Property {
        uint256 id;
        string description;
        address currentOwner;
    }

    mapping(uint256 => Property) public properties;
    mapping(uint256 => address) public propertyOwners;

    event PropertyRegistered(uint256 indexed propertyId, address indexed initialOwner, string description);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyPropertyOwner(uint256 _propertyId) {
        require(propertyOwners[_propertyId] == msg.sender, "Only the property owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Registers a new property and assigns it to an initial owner.
     * Can only be called by the contract owner.
     * @param _initialOwner The address of the first owner of the property.
     * @param _description A description of the property.
     * @return The ID of the newly registered property.
     */
    function registerProperty(address _initialOwner, string memory _description) external onlyOwner returns (uint256) {
        require(_initialOwner != address(0), "Initial owner cannot be the zero address.");
        
        _propertyIdCounter++;
        uint256 newPropertyId = _propertyIdCounter;

        properties[newPropertyId] = Property({
            id: newPropertyId,
            description: _description,
            currentOwner: _initialOwner
        });
        propertyOwners[newPropertyId] = _initialOwner;

        emit PropertyRegistered(newPropertyId, _initialOwner, _description);
        return newPropertyId;
    }

    /**
     * @dev Transfers ownership of a property from the current owner to a new owner.
     * @param _propertyId The ID of the property to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferProperty(uint256 _propertyId, address _newOwner) external onlyPropertyOwner(_propertyId) {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        require(propertyOwners[_propertyId] != _newOwner, "New owner is the same as the current owner.");

        address oldOwner = propertyOwners[_propertyId];
        properties[_propertyId].currentOwner = _newOwner;
        propertyOwners[_propertyId] = _newOwner;

        emit PropertyTransferred(_propertyId, oldOwner, _newOwner);
    }

    /**
     * @dev Verifies the ownership of a given property.
     * @param _propertyId The ID of the property to verify.
     * @return The address of the current owner.
     */
    function getPropertyOwner(uint256 _propertyId) external view returns (address) {
        return propertyOwners[_propertyId];
    }

    /**
     * @dev Retrieves the details of a property.
     * @param _propertyId The ID of the property.
     * @return The property's description and current owner.
     */
    function getPropertyDetails(uint256 _propertyId) external view returns (string memory, address) {
        Property storage prop = properties[_propertyId];
        return (prop.description, prop.currentOwner);
    }
}
