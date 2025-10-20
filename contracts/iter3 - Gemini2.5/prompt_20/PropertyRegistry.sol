// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PropertyRegistry
 * @dev A contract for registering and managing property ownership on-chain.
 * The owner of the contract acts as the central authority for managing records.
 */
contract PropertyRegistry {
    struct Property {
        uint256 id;
        string details; // e.g., address, description
        address owner;
        bool isRegistered;
    }

    address public contractOwner;
    uint256 private _propertyIdCounter;
    mapping(uint256 => Property) public properties;

    /**
     * @dev Emitted when a new property is registered.
     * @param propertyId The unique ID of the property.
     * @param owner The address of the property owner.
     * @param details A description of the property.
     */
    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed owner,
        string details
    );

    /**
     * @dev Emitted when the ownership of a property is transferred.
     * @param propertyId The ID of the property.
     * @param from The previous owner.
     * @param to The new owner.
     */
    event PropertyTransferred(
        uint256 indexed propertyId,
        address indexed from,
        address indexed to
    );

    /**
     * @dev Modifier to restrict certain functions to the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the contract owner upon deployment.
     */
    constructor() {
        contractOwner = msg.sender;
    }

    /**
     * @dev Registers a new property and assigns it to an owner.
     * Only the contract owner can perform this action.
     * @param _owner The address of the property owner.
     * @param _details A string containing details about the property.
     */
    function registerProperty(address _owner, string memory _details) public onlyOwner {
        require(_owner != address(0), "Owner address cannot be the zero address.");
        
        _propertyIdCounter++;
        uint256 newPropertyId = _propertyIdCounter;

        properties[newPropertyId] = Property({
            id: newPropertyId,
            details: _details,
            owner: _owner,
            isRegistered: true
        });

        emit PropertyRegistered(newPropertyId, _owner, _details);
    }

    /**
     * @dev Transfers ownership of a registered property from one address to another.
     * Only the contract owner can initiate a transfer.
     * @param _propertyId The ID of the property to be transferred.
     * @param _newOwner The address of the new owner.
     */
    function transferProperty(uint256 _propertyId, address _newOwner) public onlyOwner {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        require(_newOwner != address(0), "New owner address cannot be the zero address.");
        
        Property storage prop = properties[_propertyId];
        address previousOwner = prop.owner;
        
        require(previousOwner != _newOwner, "New owner is the same as the current owner.");

        prop.owner = _newOwner;
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner);
    }

    /**
     * @dev Verifies the ownership of a property.
     * @param _propertyId The ID of the property to verify.
     * @return The address of the current owner of the property.
     */
    function verifyOwnership(uint256 _propertyId) public view returns (address) {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        return properties[_propertyId].owner;
    }

    /**
     * @dev Retrieves the details of a specific property.
     * @param _propertyId The ID of the property.
     * @return A tuple containing the property's ID, details, owner, and registration status.
     */
    function getProperty(uint256 _propertyId) public view returns (uint256, string memory, address, bool) {
        Property storage prop = properties[_propertyId];
        return (prop.id, prop.details, prop.owner, prop.isRegistered);
    }

    /**
     * @dev Allows the contract owner to transfer their administrative role.
     * @param _newContractOwner The address of the new contract owner.
     */
    function transferContractOwnership(address _newContractOwner) public onlyOwner {
        require(_newContractOwner != address(0), "New contract owner cannot be the zero address.");
        contractOwner = _newContractOwner;
    }
}
