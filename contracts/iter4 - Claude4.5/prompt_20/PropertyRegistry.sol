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
        bool isRegistered;
    }
    
    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties;
    mapping(string => uint256) public propertyAddressToId;
    
    // Events
    event PropertyRegistered(uint256 indexed propertyId, address indexed owner, string propertyAddress, uint256 timestamp);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 timestamp);
    event PropertyUpdated(uint256 indexed propertyId, string newDescription, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyRegistryOwner() {
        require(msg.sender == registryOwner, "Only registry owner can call this function");
        _;
    }
    
    modifier onlyPropertyOwner(uint256 _propertyId) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].owner == msg.sender, "Only property owner can call this function");
        _;
    }
    
    constructor() {
        registryOwner = msg.sender;
    }
    
    /**
     * @dev Registers a new property
     * @param _propertyAddress The address/location of the property
     * @param _description Description of the property
     * @param _owner The owner of the property
     */
    function registerProperty(
        string memory _propertyAddress,
        string memory _description,
        address _owner
    ) external onlyRegistryOwner {
        require(bytes(_propertyAddress).length > 0, "Property address cannot be empty");
        require(_owner != address(0), "Invalid owner address");
        require(propertyAddressToId[_propertyAddress] == 0, "Property already registered");
        
        propertyCount++;
        
        properties[propertyCount] = Property({
            id: propertyCount,
            propertyAddress: _propertyAddress,
            description: _description,
            owner: _owner,
            registeredAt: block.timestamp,
            isRegistered: true
        });
        
        ownerProperties[_owner].push(propertyCount);
        propertyAddressToId[_propertyAddress] = propertyCount;
        
        emit PropertyRegistered(propertyCount, _owner, _propertyAddress, block.timestamp);
    }
    
    /**
     * @dev Transfers property ownership from current owner to a new owner
     * @param _propertyId The ID of the property
     * @param _newOwner The address of the new owner
     */
    function transferProperty(uint256 _propertyId, address _newOwner) external onlyPropertyOwner(_propertyId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "New owner must be different from current owner");
        
        Property storage property = properties[_propertyId];
        address previousOwner = property.owner;
        
        property.owner = _newOwner;
        ownerProperties[_newOwner].push(_propertyId);
        
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner, block.timestamp);
    }
    
    /**
     * @dev Allows registry owner to transfer property ownership (for administrative purposes)
     * @param _propertyId The ID of the property
     * @param _newOwner The address of the new owner
     */
    function adminTransferProperty(uint256 _propertyId, address _newOwner) external onlyRegistryOwner {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(_newOwner != address(0), "Invalid new owner address");
        
        Property storage property = properties[_propertyId];
        require(property.isRegistered, "Property not registered");
        
        address previousOwner = property.owner;
        require(_newOwner != previousOwner, "New owner must be different from current owner");
        
        property.owner = _newOwner;
        ownerProperties[_newOwner].push(_propertyId);
        
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner, block.timestamp);
    }
    
    /**
     * @dev Updates the description of a property
     * @param _propertyId The ID of the property
     * @param _newDescription The new description
     */
    function updatePropertyDescription(uint256 _propertyId, string memory _newDescription) 
        external 
        onlyRegistryOwner 
    {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].isRegistered, "Property not registered");
        
        properties[_propertyId].description = _newDescription;
        
        emit PropertyUpdated(_propertyId, _newDescription, block.timestamp);
    }
    
    /**
     * @dev Verifies the ownership of a property
     * @param _propertyId The ID of the property
     * @param _owner The address to verify
     * @return True if the address owns the property, false otherwise
     */
    function verifyOwnership(uint256 _propertyId, address _owner) external view returns (bool) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        
        return properties[_propertyId].owner == _owner && properties[_propertyId].isRegistered;
    }
    
    /**
     * @dev Returns the details of a property
     * @param _propertyId The ID of the property
     * @return id The property ID
     * @return propertyAddress The property address/location
     * @return description The property description
     * @return owner The current owner
     * @return registeredAt When the property was registered
     * @return isRegistered Whether the property is registered
     */
    function getProperty(uint256 _propertyId) external view returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registeredAt,
        bool isRegistered
    ) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        
        Property memory property = properties[_propertyId];
        
        return (
            property.id,
            property.propertyAddress,
            property.description,
            property.owner,
            property.registeredAt,
            property.isRegistered
        );
    }
    
    /**
     * @dev Returns the property ID for a given property address
     * @param _propertyAddress The property address/location
     * @return The property ID (0 if not found)
     */
    function getPropertyIdByAddress(string memory _propertyAddress) external view returns (uint256) {
        return propertyAddressToId[_propertyAddress];
    }
    
    /**
     * @dev Returns all properties owned by a specific address
     * @param _owner The address of the owner
     * @return Array of property IDs
     */
    function getPropertiesByOwner(address _owner) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count properties still owned by the address
        for (uint256 i = 0; i < ownerProperties[_owner].length; i++) {
            uint256 propertyId = ownerProperties[_owner][i];
            if (properties[propertyId].owner == _owner) {
                count++;
            }
        }
        
        // Create array of current property IDs
        uint256[] memory currentProperties = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < ownerProperties[_owner].length; i++) {
            uint256 propertyId = ownerProperties[_owner][i];
            if (properties[propertyId].owner == _owner) {
                currentProperties[index] = propertyId;
                index++;
            }
        }
        
        return currentProperties;
    }
    
    /**
     * @dev Returns all properties owned by the caller
     * @return Array of property IDs
     */
    function getMyProperties() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < ownerProperties[msg.sender].length; i++) {
            uint256 propertyId = ownerProperties[msg.sender][i];
            if (properties[propertyId].owner == msg.sender) {
                count++;
            }
        }
        
        uint256[] memory myProperties = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < ownerProperties[msg.sender].length; i++) {
            uint256 propertyId = ownerProperties[msg.sender][i];
            if (properties[propertyId].owner == msg.sender) {
                myProperties[index] = propertyId;
                index++;
            }
        }
        
        return myProperties;
    }
    
    /**
     * @dev Returns the current owner of a property
     * @param _propertyId The ID of the property
     * @return The owner's address
     */
    function getPropertyOwner(uint256 _propertyId) external view returns (address) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        
        return properties[_propertyId].owner;
    }
    
    /**
     * @dev Checks if a property is registered
     * @param _propertyId The ID of the property
     * @return True if registered, false otherwise
     */
    function isPropertyRegistered(uint256 _propertyId) external view returns (bool) {
        if (_propertyId == 0 || _propertyId > propertyCount) {
            return false;
        }
        
        return properties[_propertyId].isRegistered;
    }
    
    /**
     * @dev Returns the total number of registered properties
     * @return The property count
     */
    function getTotalProperties() external view returns (uint256) {
        return propertyCount;
    }
    
    /**
     * @dev Returns all registered properties
     * @return Array of all properties
     */
    function getAllProperties() external view returns (Property[] memory) {
        Property[] memory allProperties = new Property[](propertyCount);
        
        for (uint256 i = 1; i <= propertyCount; i++) {
            allProperties[i - 1] = properties[i];
        }
        
        return allProperties;
    }
    
    /**
     * @dev Transfers registry ownership to a new owner
     * @param _newOwner The address of the new registry owner
     */
    function transferRegistryOwnership(address _newOwner) external onlyRegistryOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != registryOwner, "New owner must be different");
        
        address previousOwner = registryOwner;
        registryOwner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
