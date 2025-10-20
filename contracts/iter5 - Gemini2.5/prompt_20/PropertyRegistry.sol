// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PropertyRegistry
 * @dev A contract for registering and managing property ownership on-chain.
 */
contract PropertyRegistry {

    address public owner;

    struct Property {
        uint256 id;
        string details; // e.g., address, size, etc.
        address currentOwner;
        bool isRegistered;
    }

    uint256 private nextPropertyId;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties; // Owner to list of property IDs

    event PropertyRegistered(uint256 indexed propertyId, string details, address indexed owner);
    event OwnershipTransferred(uint256 indexed propertyId, address indexed from, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Registers a new property and assigns it to an owner.
     * @param _details A description of the property.
     * @param _initialOwner The initial owner of the property.
     */
    function registerProperty(string memory _details, address _initialOwner) public onlyOwner {
        require(_initialOwner != address(0), "Initial owner cannot be the zero address.");
        
        uint256 propertyId = nextPropertyId;
        properties[propertyId] = Property({
            id: propertyId,
            details: _details,
            currentOwner: _initialOwner,
            isRegistered: true
        });
        
        ownerProperties[_initialOwner].push(propertyId);
        nextPropertyId++;
        
        emit PropertyRegistered(propertyId, _details, _initialOwner);
    }

    /**
     * @dev Transfers ownership of a property from the current owner to a new owner.
     * @param _propertyId The ID of the property to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(uint256 _propertyId, address _newOwner) public {
        Property storage prop = properties[_propertyId];
        require(prop.isRegistered, "Property is not registered.");
        require(prop.currentOwner == msg.sender, "Only the current owner can transfer ownership.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address from = prop.currentOwner;
        
        // Remove property from old owner's list
        _removePropertyFromOwner(from, _propertyId);
        
        // Add property to new owner's list
        prop.currentOwner = _newOwner;
        ownerProperties[_newOwner].push(_propertyId);
        
        emit OwnershipTransferred(_propertyId, from, _newOwner);
    }

    /**
     * @dev Verifies the owner of a given property.
     * @param _propertyId The ID of the property.
     * @return The address of the current owner.
     */
    function verifyOwnership(uint256 _propertyId) public view returns (address) {
        require(properties[_propertyId].isRegistered, "Property is not registered.");
        return properties[_propertyId].currentOwner;
    }

    /**
     * @dev Helper function to remove a property from an owner's list.
     */
    function _removePropertyFromOwner(address _owner, uint256 _propertyId) private {
        uint256[] storage ownerProps = ownerProperties[_owner];
        for (uint i = 0; i < ownerProps.length; i++) {
            if (ownerProps[i] == _propertyId) {
                ownerProps[i] = ownerProps[ownerProps.length - 1];
                ownerProps.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Retrieves all properties owned by a specific address.
     * @param _owner The address of the owner.
     * @return An array of property IDs.
     */
    function getPropertiesByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerProperties[_owner];
    }
}
