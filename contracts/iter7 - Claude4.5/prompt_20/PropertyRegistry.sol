// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PropertyRegistry
 * @dev A contract for a property registry where the owner can register, transfer, and verify property ownership records
 */
contract PropertyRegistry {
    address public registryOwner;
    
    // Property structure
    struct Property {
        uint256 id;
        string propertyAddress;
        string description;
        address owner;
        uint256 registeredAt;
        bool exists;
    }
    
    // Transfer history structure
    struct TransferRecord {
        uint256 propertyId;
        address from;
        address to;
        uint256 timestamp;
    }
    
    // State variables
    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties;
    mapping(uint256 => TransferRecord[]) public propertyTransferHistory;
    
    // Events
    event PropertyRegistered(uint256 indexed propertyId, string propertyAddress, address indexed owner, uint256 timestamp);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 timestamp);
    event PropertyUpdated(uint256 indexed propertyId, string newDescription);
    event RegistryOwnerChanged(address indexed oldOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyRegistryOwner() {
        require(msg.sender == registryOwner, "Only registry owner can perform this action");
        _;
    }
    
    modifier propertyExists(uint256 propertyId) {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");
        require(properties[propertyId].exists, "Property does not exist");
        _;
    }
    
    /**
     * @dev Constructor sets the registry owner
     */
    constructor() {
        registryOwner = msg.sender;
    }
    
    /**
     * @dev Register a new property
     * @param propertyAddress The physical address of the property
     * @param description The description of the property
     * @param owner The initial owner of the property
     * @return propertyId The ID of the registered property
     */
    function registerProperty(
        string memory propertyAddress,
        string memory description,
        address owner
    ) external onlyRegistryOwner returns (uint256) {
        require(bytes(propertyAddress).length > 0, "Property address cannot be empty");
        require(owner != address(0), "Invalid owner address");
        
        propertyCount++;
        uint256 propertyId = propertyCount;
        
        properties[propertyId] = Property({
            id: propertyId,
            propertyAddress: propertyAddress,
            description: description,
            owner: owner,
            registeredAt: block.timestamp,
            exists: true
        });
        
        ownerProperties[owner].push(propertyId);
        
        emit PropertyRegistered(propertyId, propertyAddress, owner, block.timestamp);
        
        return propertyId;
    }
    
    /**
     * @dev Transfer property ownership
     * @param propertyId The ID of the property to transfer
     * @param newOwner The address of the new owner
     */
    function transferProperty(uint256 propertyId, address newOwner) external propertyExists(propertyId) {
        Property storage property = properties[propertyId];
        
        require(msg.sender == property.owner || msg.sender == registryOwner, "Only property owner or registry owner can transfer");
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != property.owner, "New owner is the same as current owner");
        
        address previousOwner = property.owner;
        
        // Remove from previous owner's list
        _removePropertyFromOwner(previousOwner, propertyId);
        
        // Update property owner
        property.owner = newOwner;
        
        // Add to new owner's list
        ownerProperties[newOwner].push(propertyId);
        
        // Record transfer history
        propertyTransferHistory[propertyId].push(TransferRecord({
            propertyId: propertyId,
            from: previousOwner,
            to: newOwner,
            timestamp: block.timestamp
        }));
        
        emit PropertyTransferred(propertyId, previousOwner, newOwner, block.timestamp);
    }
    
    /**
     * @dev Internal function to remove property from owner's list
     * @param owner The owner's address
     * @param propertyId The property ID to remove
     */
    function _removePropertyFromOwner(address owner, uint256 propertyId) internal {
        uint256[] storage properties = ownerProperties[owner];
        
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i] == propertyId) {
                // Swap with last element and pop
                properties[i] = properties[properties.length - 1];
                properties.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Update property description
     * @param propertyId The ID of the property
     * @param newDescription The new description
     */
    function updatePropertyDescription(uint256 propertyId, string memory newDescription) external propertyExists(propertyId) {
        require(msg.sender == properties[propertyId].owner || msg.sender == registryOwner, "Only property owner or registry owner can update");
        
        properties[propertyId].description = newDescription;
        
        emit PropertyUpdated(propertyId, newDescription);
    }
    
    /**
     * @dev Verify property ownership
     * @param propertyId The ID of the property
     * @param claimedOwner The address claiming ownership
     * @return True if the claimed owner is the actual owner, false otherwise
     */
    function verifyOwnership(uint256 propertyId, address claimedOwner) external view propertyExists(propertyId) returns (bool) {
        return properties[propertyId].owner == claimedOwner;
    }
    
    /**
     * @dev Get property details
     * @param propertyId The ID of the property
     * @return id Property ID
     * @return propertyAddress Property address
     * @return description Property description
     * @return owner Current owner
     * @return registeredAt Registration timestamp
     * @return exists Whether property exists
     */
    function getProperty(uint256 propertyId) external view propertyExists(propertyId) returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registeredAt,
        bool exists
    ) {
        Property memory property = properties[propertyId];
        return (
            property.id,
            property.propertyAddress,
            property.description,
            property.owner,
            property.registeredAt,
            property.exists
        );
    }
    
    /**
     * @dev Get current owner of a property
     * @param propertyId The ID of the property
     * @return The current owner's address
     */
    function getPropertyOwner(uint256 propertyId) external view propertyExists(propertyId) returns (address) {
        return properties[propertyId].owner;
    }
    
    /**
     * @dev Get all properties owned by an address
     * @param owner The owner's address
     * @return Array of property IDs
     */
    function getPropertiesByOwner(address owner) external view returns (uint256[] memory) {
        return ownerProperties[owner];
    }
    
    /**
     * @dev Get transfer history for a property
     * @param propertyId The ID of the property
     * @return Array of transfer records
     */
    function getPropertyTransferHistory(uint256 propertyId) external view propertyExists(propertyId) returns (TransferRecord[] memory) {
        return propertyTransferHistory[propertyId];
    }
    
    /**
     * @dev Get the number of transfers for a property
     * @param propertyId The ID of the property
     * @return The number of transfers
     */
    function getTransferCount(uint256 propertyId) external view propertyExists(propertyId) returns (uint256) {
        return propertyTransferHistory[propertyId].length;
    }
    
    /**
     * @dev Get all properties owned by the caller
     * @return Array of property IDs
     */
    function getMyProperties() external view returns (uint256[] memory) {
        return ownerProperties[msg.sender];
    }
    
    /**
     * @dev Check if an address owns any properties
     * @param owner The address to check
     * @return True if the address owns at least one property, false otherwise
     */
    function hasProperties(address owner) external view returns (bool) {
        return ownerProperties[owner].length > 0;
    }
    
    /**
     * @dev Get the number of properties owned by an address
     * @param owner The owner's address
     * @return The number of properties owned
     */
    function getPropertyCount(address owner) external view returns (uint256) {
        return ownerProperties[owner].length;
    }
    
    /**
     * @dev Get all registered properties
     * @return Array of all property IDs
     */
    function getAllProperties() external view returns (uint256[] memory) {
        uint256 existingCount = 0;
        
        // Count existing properties
        for (uint256 i = 1; i <= propertyCount; i++) {
            if (properties[i].exists) {
                existingCount++;
            }
        }
        
        // Create array
        uint256[] memory allPropertyIds = new uint256[](existingCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= propertyCount; i++) {
            if (properties[i].exists) {
                allPropertyIds[index] = i;
                index++;
            }
        }
        
        return allPropertyIds;
    }
    
    /**
     * @dev Transfer registry ownership
     * @param newRegistryOwner The address of the new registry owner
     */
    function transferRegistryOwnership(address newRegistryOwner) external onlyRegistryOwner {
        require(newRegistryOwner != address(0), "Invalid new registry owner address");
        require(newRegistryOwner != registryOwner, "New owner is the same as current owner");
        
        address oldOwner = registryOwner;
        registryOwner = newRegistryOwner;
        
        emit RegistryOwnerChanged(oldOwner, newRegistryOwner);
    }
    
    /**
     * @dev Check if caller is the owner of a specific property
     * @param propertyId The ID of the property
     * @return True if caller is the owner, false otherwise
     */
    function isMyProperty(uint256 propertyId) external view propertyExists(propertyId) returns (bool) {
        return properties[propertyId].owner == msg.sender;
    }
}
