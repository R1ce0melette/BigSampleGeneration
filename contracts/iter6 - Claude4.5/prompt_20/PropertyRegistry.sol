// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PropertyRegistry
 * @dev A contract for a property registry where properties can be registered, transferred, and verified
 */
contract PropertyRegistry {
    address public registryOwner;
    
    struct Property {
        uint256 id;
        string propertyAddress;
        string description;
        address owner;
        uint256 registeredAt;
        bool exists;
    }
    
    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties;
    
    // Events
    event PropertyRegistered(uint256 indexed propertyId, string propertyAddress, address indexed owner, uint256 timestamp);
    event PropertyTransferred(uint256 indexed propertyId, address indexed previousOwner, address indexed newOwner, uint256 timestamp);
    event RegistryOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyRegistryOwner() {
        require(msg.sender == registryOwner, "Only registry owner can perform this action");
        _;
    }
    
    constructor() {
        registryOwner = msg.sender;
    }
    
    /**
     * @dev Register a new property
     * @param propertyAddress The physical address of the property
     * @param description Description of the property
     * @param owner The owner of the property
     */
    function registerProperty(
        string memory propertyAddress,
        string memory description,
        address owner
    ) external onlyRegistryOwner {
        require(bytes(propertyAddress).length > 0, "Property address cannot be empty");
        require(owner != address(0), "Invalid owner address");
        
        propertyCount++;
        
        properties[propertyCount] = Property({
            id: propertyCount,
            propertyAddress: propertyAddress,
            description: description,
            owner: owner,
            registeredAt: block.timestamp,
            exists: true
        });
        
        ownerProperties[owner].push(propertyCount);
        
        emit PropertyRegistered(propertyCount, propertyAddress, owner, block.timestamp);
    }
    
    /**
     * @dev Transfer property ownership
     * @param propertyId The ID of the property
     * @param newOwner The new owner's address
     */
    function transferProperty(uint256 propertyId, address newOwner) external {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");
        Property storage property = properties[propertyId];
        
        require(property.exists, "Property does not exist");
        require(msg.sender == property.owner || msg.sender == registryOwner, "Not authorized to transfer");
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != property.owner, "New owner is the same as current owner");
        
        address previousOwner = property.owner;
        property.owner = newOwner;
        
        // Add to new owner's list
        ownerProperties[newOwner].push(propertyId);
        
        emit PropertyTransferred(propertyId, previousOwner, newOwner, block.timestamp);
    }
    
    /**
     * @dev Verify property ownership
     * @param propertyId The ID of the property
     * @param owner The address to verify
     * @return True if the address owns the property, false otherwise
     */
    function verifyOwnership(uint256 propertyId, address owner) external view returns (bool) {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");
        Property memory property = properties[propertyId];
        
        return property.exists && property.owner == owner;
    }
    
    /**
     * @dev Get property details
     * @param propertyId The ID of the property
     * @return id Property ID
     * @return propertyAddress Physical address
     * @return description Property description
     * @return owner Current owner
     * @return registeredAt Registration timestamp
     * @return exists Whether the property exists
     */
    function getProperty(uint256 propertyId) external view returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registeredAt,
        bool exists
    ) {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");
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
     * @dev Get the current owner of a property
     * @param propertyId The ID of the property
     * @return The owner's address
     */
    function getPropertyOwner(uint256 propertyId) external view returns (address) {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");
        require(properties[propertyId].exists, "Property does not exist");
        
        return properties[propertyId].owner;
    }
    
    /**
     * @dev Get all properties owned by an address
     * @param owner The owner's address
     * @return Array of property IDs
     */
    function getPropertiesByOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory ownedProperties = ownerProperties[owner];
        uint256 validCount = 0;
        
        // Count currently owned properties
        for (uint256 i = 0; i < ownedProperties.length; i++) {
            if (properties[ownedProperties[i]].owner == owner) {
                validCount++;
            }
        }
        
        // Create array with current properties only
        uint256[] memory currentProperties = new uint256[](validCount);
        uint256 index = 0;
        for (uint256 i = 0; i < ownedProperties.length; i++) {
            if (properties[ownedProperties[i]].owner == owner) {
                currentProperties[index] = ownedProperties[i];
                index++;
            }
        }
        
        return currentProperties;
    }
    
    /**
     * @dev Get all property IDs
     * @return Array of all property IDs
     */
    function getAllPropertyIds() external view returns (uint256[] memory) {
        uint256[] memory propertyIds = new uint256[](propertyCount);
        for (uint256 i = 0; i < propertyCount; i++) {
            propertyIds[i] = i + 1;
        }
        return propertyIds;
    }
    
    /**
     * @dev Get the total number of properties registered
     * @return The total property count
     */
    function getTotalProperties() external view returns (uint256) {
        return propertyCount;
    }
    
    /**
     * @dev Get the number of properties owned by an address
     * @param owner The owner's address
     * @return The number of properties owned
     */
    function getPropertyCountByOwner(address owner) external view returns (uint256) {
        uint256 count = 0;
        uint256[] memory ownedProperties = ownerProperties[owner];
        
        for (uint256 i = 0; i < ownedProperties.length; i++) {
            if (properties[ownedProperties[i]].owner == owner) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Update property description (registry owner or property owner only)
     * @param propertyId The ID of the property
     * @param newDescription The new description
     */
    function updatePropertyDescription(uint256 propertyId, string memory newDescription) external {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");
        Property storage property = properties[propertyId];
        
        require(property.exists, "Property does not exist");
        require(
            msg.sender == property.owner || msg.sender == registryOwner,
            "Not authorized to update description"
        );
        require(bytes(newDescription).length > 0, "Description cannot be empty");
        
        property.description = newDescription;
    }
    
    /**
     * @dev Check if a property exists
     * @param propertyId The ID of the property
     * @return True if the property exists, false otherwise
     */
    function propertyExists(uint256 propertyId) external view returns (bool) {
        if (propertyId == 0 || propertyId > propertyCount) {
            return false;
        }
        return properties[propertyId].exists;
    }
    
    /**
     * @dev Transfer registry ownership to a new address
     * @param newOwner The new registry owner's address
     */
    function transferRegistryOwnership(address newOwner) external onlyRegistryOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != registryOwner, "New owner is the same as current owner");
        
        address previousOwner = registryOwner;
        registryOwner = newOwner;
        
        emit RegistryOwnershipTransferred(previousOwner, newOwner);
    }
}
