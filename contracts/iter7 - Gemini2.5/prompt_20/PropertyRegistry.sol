// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PropertyRegistry
 * @dev A contract for registering and managing property ownership on-chain.
 * Only the contract owner can manage property records.
 */
contract PropertyRegistry {
    // The address of the contract owner.
    address public owner;

    // Struct to represent a property.
    struct Property {
        uint256 id;
        string details; // e.g., address, size, etc.
        address currentOwner;
    }

    // Counter for generating unique property IDs.
    uint256 private _propertyIds;

    // Mapping from property ID to the Property struct.
    mapping(uint256 => Property) public properties;

    // Mapping from an owner's address to the list of property IDs they own.
    mapping(address => uint256[]) public ownerProperties;

    /**
     * @dev Emitted when a new property is registered.
     * @param propertyId The unique ID of the property.
     * @param owner The address of the initial owner.
     */
    event PropertyRegistered(uint256 indexed propertyId, address indexed owner);

    /**
     * @dev Emitted when a property is transferred to a new owner.
     * @param propertyId The ID of the transferred property.
     * @param from The address of the previous owner.
     * @param to The address of the new owner.
     */
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "PropertyRegistry: Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Registers a new property and assigns it to an owner.
     * @param _details A description of the property.
     * @param _initialOwner The address of the first owner of the property.
     */
    function registerProperty(string memory _details, address _initialOwner) public onlyOwner {
        require(bytes(_details).length > 0, "Property details cannot be empty.");
        require(_initialOwner != address(0), "Initial owner cannot be the zero address.");

        _propertyIds++;
        uint256 newPropertyId = _propertyIds;

        properties[newPropertyId] = Property({
            id: newPropertyId,
            details: _details,
            currentOwner: _initialOwner
        });

        ownerProperties[_initialOwner].push(newPropertyId);

        emit PropertyRegistered(newPropertyId, _initialOwner);
    }

    /**
     * @dev Transfers a property from its current owner to a new owner.
     * @param _propertyId The ID of the property to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferProperty(uint256 _propertyId, address _newOwner) public onlyOwner {
        Property storage prop = properties[_propertyId];
        require(prop.id != 0, "Property does not exist.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address previousOwner = prop.currentOwner;
        require(previousOwner != _newOwner, "New owner is the same as the current owner.");

        // Remove property from the old owner's list
        uint256[] storage oldOwnerProps = ownerProperties[previousOwner];
        for (uint i = 0; i < oldOwnerProps.length; i++) {
            if (oldOwnerProps[i] == _propertyId) {
                oldOwnerProps[i] = oldOwnerProps[oldOwnerProps.length - 1];
                oldOwnerProps.pop();
                break;
            }
        }

        // Add property to the new owner's list
        prop.currentOwner = _newOwner;
        ownerProperties[_newOwner].push(_propertyId);

        emit PropertyTransferred(_propertyId, previousOwner, _newOwner);
    }

    /**
     * @dev Verifies the owner of a specific property.
     * @param _propertyId The ID of the property to verify.
     * @return The address of the current owner.
     */
    function verifyOwnership(uint256 _propertyId) public view returns (address) {
        require(properties[_propertyId].id != 0, "Property does not exist.");
        return properties[_propertyId].currentOwner;
    }

    /**
     * @dev Retrieves the list of properties owned by a specific address.
     * @param _owner The address of the owner.
     * @return An array of property IDs.
     */
    function getPropertiesByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerProperties[_owner];
    }
}
