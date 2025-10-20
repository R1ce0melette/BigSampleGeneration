// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public registrar;
    
    struct Property {
        uint256 id;
        string propertyAddress;
        string description;
        address owner;
        uint256 registeredAt;
        bool exists;
    }
    
    struct TransferHistory {
        address from;
        address to;
        uint256 timestamp;
    }
    
    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(uint256 => TransferHistory[]) public transferHistory;
    mapping(address => uint256[]) public ownerProperties;
    mapping(string => uint256) public addressToPropertyId;
    
    // Events
    event PropertyRegistered(uint256 indexed propertyId, string propertyAddress, address indexed owner);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to);
    event PropertyUpdated(uint256 indexed propertyId, string newDescription);
    event RegistrarTransferred(address indexed previousRegistrar, address indexed newRegistrar);
    
    modifier onlyRegistrar() {
        require(msg.sender == registrar, "Only registrar can call this function");
        _;
    }
    
    modifier onlyPropertyOwner(uint256 _propertyId) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].owner == msg.sender, "Only property owner can call this function");
        _;
    }
    
    constructor() {
        registrar = msg.sender;
    }
    
    /**
     * @dev Register a new property
     * @param _propertyAddress The physical address of the property
     * @param _description Property description
     * @param _owner The initial owner address
     */
    function registerProperty(
        string memory _propertyAddress,
        string memory _description,
        address _owner
    ) external onlyRegistrar {
        require(bytes(_propertyAddress).length > 0, "Property address cannot be empty");
        require(_owner != address(0), "Invalid owner address");
        require(addressToPropertyId[_propertyAddress] == 0, "Property already registered");
        
        propertyCount++;
        
        properties[propertyCount] = Property({
            id: propertyCount,
            propertyAddress: _propertyAddress,
            description: _description,
            owner: _owner,
            registeredAt: block.timestamp,
            exists: true
        });
        
        addressToPropertyId[_propertyAddress] = propertyCount;
        ownerProperties[_owner].push(propertyCount);
        
        emit PropertyRegistered(propertyCount, _propertyAddress, _owner);
    }
    
    /**
     * @dev Transfer property ownership
     * @param _propertyId The ID of the property
     * @param _newOwner The new owner address
     */
    function transferProperty(uint256 _propertyId, address _newOwner) external onlyPropertyOwner(_propertyId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        
        Property storage property = properties[_propertyId];
        address previousOwner = property.owner;
        
        // Update owner
        property.owner = _newOwner;
        
        // Add to new owner's properties
        ownerProperties[_newOwner].push(_propertyId);
        
        // Record transfer history
        transferHistory[_propertyId].push(TransferHistory({
            from: previousOwner,
            to: _newOwner,
            timestamp: block.timestamp
        }));
        
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner);
    }
    
    /**
     * @dev Registrar can force transfer (e.g., for court orders)
     * @param _propertyId The ID of the property
     * @param _newOwner The new owner address
     */
    function registrarTransferProperty(uint256 _propertyId, address _newOwner) external onlyRegistrar {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].exists, "Property does not exist");
        require(_newOwner != address(0), "Invalid new owner address");
        
        Property storage property = properties[_propertyId];
        address previousOwner = property.owner;
        
        require(_newOwner != previousOwner, "New owner is the same as current owner");
        
        // Update owner
        property.owner = _newOwner;
        
        // Add to new owner's properties
        ownerProperties[_newOwner].push(_propertyId);
        
        // Record transfer history
        transferHistory[_propertyId].push(TransferHistory({
            from: previousOwner,
            to: _newOwner,
            timestamp: block.timestamp
        }));
        
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner);
    }
    
    /**
     * @dev Update property description
     * @param _propertyId The ID of the property
     * @param _newDescription The new description
     */
    function updatePropertyDescription(uint256 _propertyId, string memory _newDescription) external onlyRegistrar {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].exists, "Property does not exist");
        
        properties[_propertyId].description = _newDescription;
        
        emit PropertyUpdated(_propertyId, _newDescription);
    }
    
    /**
     * @dev Verify property ownership
     * @param _propertyId The ID of the property
     * @param _owner The address to verify
     * @return True if the address owns the property, false otherwise
     */
    function verifyOwnership(uint256 _propertyId, address _owner) external view returns (bool) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].exists, "Property does not exist");
        
        return properties[_propertyId].owner == _owner;
    }
    
    /**
     * @dev Get property details
     * @param _propertyId The ID of the property
     * @return id The property ID
     * @return propertyAddress The property address
     * @return description The property description
     * @return owner The current owner
     * @return registeredAt The registration timestamp
     */
    function getProperty(uint256 _propertyId) external view returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registeredAt
    ) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].exists, "Property does not exist");
        
        Property memory property = properties[_propertyId];
        
        return (
            property.id,
            property.propertyAddress,
            property.description,
            property.owner,
            property.registeredAt
        );
    }
    
    /**
     * @dev Get property ID by address
     * @param _propertyAddress The property address
     * @return The property ID (0 if not found)
     */
    function getPropertyIdByAddress(string memory _propertyAddress) external view returns (uint256) {
        return addressToPropertyId[_propertyAddress];
    }
    
    /**
     * @dev Get all properties owned by an address
     * @param _owner The owner address
     * @return Array of property IDs
     */
    function getPropertiesByOwner(address _owner) external view returns (uint256[] memory) {
        return ownerProperties[_owner];
    }
    
    /**
     * @dev Get transfer history for a property
     * @param _propertyId The ID of the property
     * @return fromAddresses Array of previous owners
     * @return toAddresses Array of new owners
     * @return timestamps Array of transfer timestamps
     */
    function getTransferHistory(uint256 _propertyId) external view returns (
        address[] memory fromAddresses,
        address[] memory toAddresses,
        uint256[] memory timestamps
    ) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        
        TransferHistory[] memory history = transferHistory[_propertyId];
        uint256 count = history.length;
        
        fromAddresses = new address[](count);
        toAddresses = new address[](count);
        timestamps = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            fromAddresses[i] = history[i].from;
            toAddresses[i] = history[i].to;
            timestamps[i] = history[i].timestamp;
        }
        
        return (fromAddresses, toAddresses, timestamps);
    }
    
    /**
     * @dev Get current owner of a property
     * @param _propertyId The ID of the property
     * @return The current owner address
     */
    function getCurrentOwner(uint256 _propertyId) external view returns (address) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].exists, "Property does not exist");
        
        return properties[_propertyId].owner;
    }
    
    /**
     * @dev Transfer registrar role to a new address
     * @param _newRegistrar The new registrar address
     */
    function transferRegistrar(address _newRegistrar) external onlyRegistrar {
        require(_newRegistrar != address(0), "Invalid registrar address");
        
        address previousRegistrar = registrar;
        registrar = _newRegistrar;
        
        emit RegistrarTransferred(previousRegistrar, _newRegistrar);
    }
    
    /**
     * @dev Get total number of properties registered
     * @return The total property count
     */
    function getTotalProperties() external view returns (uint256) {
        return propertyCount;
    }
}
