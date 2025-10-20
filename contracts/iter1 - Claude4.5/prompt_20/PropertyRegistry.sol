// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PropertyRegistry
 * @dev A contract for a property registry where the owner can register, transfer, and verify property ownership records
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
    
    struct TransferRecord {
        uint256 propertyId;
        address from;
        address to;
        uint256 timestamp;
    }
    
    uint256 private propertyCounter;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) private ownerProperties;
    mapping(uint256 => TransferRecord[]) private transferHistory;
    
    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed owner,
        string propertyAddress
    );
    
    event PropertyTransferred(
        uint256 indexed propertyId,
        address indexed from,
        address indexed to,
        uint256 timestamp
    );
    
    event PropertyUpdated(uint256 indexed propertyId);
    
    modifier onlyRegistryOwner() {
        require(msg.sender == registryOwner, "Only registry owner can call this function");
        _;
    }
    
    modifier onlyPropertyOwner(uint256 propertyId) {
        require(properties[propertyId].exists, "Property does not exist");
        require(properties[propertyId].owner == msg.sender, "Only property owner can call this function");
        _;
    }
    
    constructor() {
        registryOwner = msg.sender;
    }
    
    /**
     * @dev Register a new property
     * @param propertyAddress Physical address of the property
     * @param description Property description
     * @param owner Initial owner of the property
     * @return propertyId The ID of the registered property
     */
    function registerProperty(
        string memory propertyAddress,
        string memory description,
        address owner
    ) external onlyRegistryOwner returns (uint256) {
        require(bytes(propertyAddress).length > 0, "Property address cannot be empty");
        require(owner != address(0), "Invalid owner address");
        
        propertyCounter++;
        uint256 propertyId = propertyCounter;
        
        properties[propertyId] = Property({
            id: propertyId,
            propertyAddress: propertyAddress,
            description: description,
            owner: owner,
            registeredAt: block.timestamp,
            exists: true
        });
        
        ownerProperties[owner].push(propertyId);
        
        emit PropertyRegistered(propertyId, owner, propertyAddress);
        
        return propertyId;
    }
    
    /**
     * @dev Transfer property ownership
     * @param propertyId The ID of the property
     * @param newOwner The address of the new owner
     */
    function transferProperty(uint256 propertyId, address newOwner) external {
        Property storage property = properties[propertyId];
        
        require(property.exists, "Property does not exist");
        require(property.owner == msg.sender, "Only property owner can transfer");
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != property.owner, "New owner cannot be the same as current owner");
        
        address previousOwner = property.owner;
        
        // Update property owner
        property.owner = newOwner;
        
        // Add to new owner's properties
        ownerProperties[newOwner].push(propertyId);
        
        // Record transfer in history
        transferHistory[propertyId].push(TransferRecord({
            propertyId: propertyId,
            from: previousOwner,
            to: newOwner,
            timestamp: block.timestamp
        }));
        
        emit PropertyTransferred(propertyId, previousOwner, newOwner, block.timestamp);
    }
    
    /**
     * @dev Registry owner can transfer property (for administrative purposes)
     * @param propertyId The ID of the property
     * @param newOwner The address of the new owner
     */
    function adminTransferProperty(uint256 propertyId, address newOwner) external onlyRegistryOwner {
        Property storage property = properties[propertyId];
        
        require(property.exists, "Property does not exist");
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != property.owner, "New owner cannot be the same as current owner");
        
        address previousOwner = property.owner;
        
        // Update property owner
        property.owner = newOwner;
        
        // Add to new owner's properties
        ownerProperties[newOwner].push(propertyId);
        
        // Record transfer in history
        transferHistory[propertyId].push(TransferRecord({
            propertyId: propertyId,
            from: previousOwner,
            to: newOwner,
            timestamp: block.timestamp
        }));
        
        emit PropertyTransferred(propertyId, previousOwner, newOwner, block.timestamp);
    }
    
    /**
     * @dev Update property details
     * @param propertyId The ID of the property
     * @param propertyAddress New property address
     * @param description New description
     */
    function updateProperty(
        uint256 propertyId,
        string memory propertyAddress,
        string memory description
    ) external onlyRegistryOwner {
        Property storage property = properties[propertyId];
        
        require(property.exists, "Property does not exist");
        require(bytes(propertyAddress).length > 0, "Property address cannot be empty");
        
        property.propertyAddress = propertyAddress;
        property.description = description;
        
        emit PropertyUpdated(propertyId);
    }
    
    /**
     * @dev Verify property ownership
     * @param propertyId The ID of the property
     * @param owner The address to verify
     * @return Whether the address owns the property
     */
    function verifyOwnership(uint256 propertyId, address owner) external view returns (bool) {
        require(properties[propertyId].exists, "Property does not exist");
        return properties[propertyId].owner == owner;
    }
    
    /**
     * @dev Get property details
     * @param propertyId The ID of the property
     * @return id Property ID
     * @return propertyAddress Physical address
     * @return description Property description
     * @return owner Current owner
     * @return registeredAt Registration timestamp
     */
    function getPropertyDetails(uint256 propertyId) external view returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registeredAt
    ) {
        Property memory property = properties[propertyId];
        require(property.exists, "Property does not exist");
        
        return (
            property.id,
            property.propertyAddress,
            property.description,
            property.owner,
            property.registeredAt
        );
    }
    
    /**
     * @dev Get all properties owned by an address
     * @param owner The address of the owner
     * @return Array of property IDs
     */
    function getPropertiesByOwner(address owner) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count properties currently owned
        for (uint256 i = 0; i < ownerProperties[owner].length; i++) {
            uint256 propId = ownerProperties[owner][i];
            if (properties[propId].owner == owner) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory ownedProperties = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < ownerProperties[owner].length; i++) {
            uint256 propId = ownerProperties[owner][i];
            if (properties[propId].owner == owner) {
                ownedProperties[index] = propId;
                index++;
            }
        }
        
        return ownedProperties;
    }
    
    /**
     * @dev Get transfer history for a property
     * @param propertyId The ID of the property
     * @return Array of transfer records
     */
    function getTransferHistory(uint256 propertyId) external view returns (TransferRecord[] memory) {
        require(properties[propertyId].exists, "Property does not exist");
        return transferHistory[propertyId];
    }
    
    /**
     * @dev Get the current owner of a property
     * @param propertyId The ID of the property
     * @return The owner's address
     */
    function getPropertyOwner(uint256 propertyId) external view returns (address) {
        require(properties[propertyId].exists, "Property does not exist");
        return properties[propertyId].owner;
    }
    
    /**
     * @dev Get total number of registered properties
     * @return The total count
     */
    function getTotalProperties() external view returns (uint256) {
        return propertyCounter;
    }
    
    /**
     * @dev Check if a property exists
     * @param propertyId The ID of the property
     * @return Whether the property exists
     */
    function propertyExists(uint256 propertyId) external view returns (bool) {
        return properties[propertyId].exists;
    }
    
    /**
     * @dev Get all registered properties
     * @return Array of property IDs
     */
    function getAllProperties() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count existing properties
        for (uint256 i = 1; i <= propertyCounter; i++) {
            if (properties[i].exists) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory allProperties = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= propertyCounter; i++) {
            if (properties[i].exists) {
                allProperties[index] = i;
                index++;
            }
        }
        
        return allProperties;
    }
    
    /**
     * @dev Get number of times a property has been transferred
     * @param propertyId The ID of the property
     * @return The transfer count
     */
    function getTransferCount(uint256 propertyId) external view returns (uint256) {
        require(properties[propertyId].exists, "Property does not exist");
        return transferHistory[propertyId].length;
    }
    
    /**
     * @dev Transfer registry ownership to a new owner
     * @param newOwner The address of the new registry owner
     */
    function transferRegistryOwnership(address newOwner) external onlyRegistryOwner {
        require(newOwner != address(0), "Invalid address");
        registryOwner = newOwner;
    }
}
