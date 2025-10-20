// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PropertyRegistry
 * @dev Property registry where the owner can register, transfer, and verify property ownership records
 */
contract PropertyRegistry {
    // Property structure
    struct Property {
        uint256 id;
        string propertyAddress;
        string description;
        address owner;
        uint256 registeredAt;
        uint256 lastTransferredAt;
        bool exists;
        string propertyType;
        uint256 area; // in square meters or feet
    }

    // Transfer history structure
    struct TransferRecord {
        uint256 id;
        uint256 propertyId;
        address fromOwner;
        address toOwner;
        uint256 timestamp;
        string notes;
    }

    // Owner statistics
    struct OwnerStats {
        uint256 propertiesOwned;
        uint256 totalPropertiesReceived;
        uint256 totalPropertiesTransferred;
    }

    // State variables
    address public registryOwner;
    uint256 private propertyCounter;
    uint256 private transferCounter;
    
    mapping(uint256 => Property) private properties;
    mapping(address => uint256[]) private ownerPropertyIds;
    mapping(string => uint256) private addressToPropertyId;
    mapping(string => bool) private propertyAddressExists;
    mapping(uint256 => TransferRecord[]) private propertyTransferHistory;
    mapping(address => OwnerStats) private ownerStats;
    mapping(address => bool) private authorizedRegistrars;
    
    uint256[] private allPropertyIds;
    TransferRecord[] private allTransfers;

    // Events
    event PropertyRegistered(uint256 indexed propertyId, string propertyAddress, address indexed owner, uint256 timestamp);
    event PropertyTransferred(uint256 indexed propertyId, address indexed fromOwner, address indexed toOwner, uint256 timestamp);
    event PropertyUpdated(uint256 indexed propertyId, address indexed owner);
    event RegistrarAuthorized(address indexed registrar);
    event RegistrarRevoked(address indexed registrar);

    // Modifiers
    modifier onlyRegistryOwner() {
        require(msg.sender == registryOwner, "Not the registry owner");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == registryOwner || authorizedRegistrars[msg.sender],
            "Not authorized"
        );
        _;
    }

    modifier propertyExists(uint256 propertyId) {
        require(
            propertyId > 0 && propertyId <= propertyCounter && properties[propertyId].exists,
            "Property does not exist"
        );
        _;
    }

    modifier onlyPropertyOwner(uint256 propertyId) {
        require(properties[propertyId].owner == msg.sender, "Not the property owner");
        _;
    }

    constructor() {
        registryOwner = msg.sender;
        propertyCounter = 0;
        transferCounter = 0;
        authorizedRegistrars[msg.sender] = true;
    }

    /**
     * @dev Register a new property
     * @param propertyAddress Property address
     * @param description Property description
     * @param owner Property owner
     * @param propertyType Type of property
     * @param area Property area
     * @return propertyId ID of the registered property
     */
    function registerProperty(
        string memory propertyAddress,
        string memory description,
        address owner,
        string memory propertyType,
        uint256 area
    ) public onlyAuthorized returns (uint256) {
        require(bytes(propertyAddress).length > 0, "Property address cannot be empty");
        require(owner != address(0), "Invalid owner address");
        require(!propertyAddressExists[propertyAddress], "Property address already registered");

        propertyCounter++;
        uint256 propertyId = propertyCounter;

        Property storage newProperty = properties[propertyId];
        newProperty.id = propertyId;
        newProperty.propertyAddress = propertyAddress;
        newProperty.description = description;
        newProperty.owner = owner;
        newProperty.registeredAt = block.timestamp;
        newProperty.lastTransferredAt = block.timestamp;
        newProperty.exists = true;
        newProperty.propertyType = propertyType;
        newProperty.area = area;

        allPropertyIds.push(propertyId);
        ownerPropertyIds[owner].push(propertyId);
        addressToPropertyId[propertyAddress] = propertyId;
        propertyAddressExists[propertyAddress] = true;

        ownerStats[owner].propertiesOwned++;
        ownerStats[owner].totalPropertiesReceived++;

        emit PropertyRegistered(propertyId, propertyAddress, owner, block.timestamp);

        return propertyId;
    }

    /**
     * @dev Transfer property ownership
     * @param propertyId Property ID
     * @param newOwner New owner address
     * @param notes Transfer notes
     */
    function transferProperty(
        uint256 propertyId,
        address newOwner,
        string memory notes
    ) public propertyExists(propertyId) {
        Property storage property = properties[propertyId];
        
        require(
            property.owner == msg.sender || msg.sender == registryOwner || authorizedRegistrars[msg.sender],
            "Not authorized to transfer"
        );
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != property.owner, "New owner is the same as current owner");

        address previousOwner = property.owner;

        // Update property
        property.owner = newOwner;
        property.lastTransferredAt = block.timestamp;

        // Update ownership tracking
        ownerPropertyIds[newOwner].push(propertyId);

        // Update statistics
        ownerStats[previousOwner].propertiesOwned--;
        ownerStats[previousOwner].totalPropertiesTransferred++;
        ownerStats[newOwner].propertiesOwned++;
        ownerStats[newOwner].totalPropertiesReceived++;

        // Record transfer
        transferCounter++;
        TransferRecord memory transferRecord = TransferRecord({
            id: transferCounter,
            propertyId: propertyId,
            fromOwner: previousOwner,
            toOwner: newOwner,
            timestamp: block.timestamp,
            notes: notes
        });

        propertyTransferHistory[propertyId].push(transferRecord);
        allTransfers.push(transferRecord);

        emit PropertyTransferred(propertyId, previousOwner, newOwner, block.timestamp);
    }

    /**
     * @dev Update property details
     * @param propertyId Property ID
     * @param description New description
     * @param propertyType New property type
     * @param area New area
     */
    function updateProperty(
        uint256 propertyId,
        string memory description,
        string memory propertyType,
        uint256 area
    ) public propertyExists(propertyId) onlyAuthorized {
        Property storage property = properties[propertyId];
        
        property.description = description;
        property.propertyType = propertyType;
        property.area = area;

        emit PropertyUpdated(propertyId, property.owner);
    }

    /**
     * @dev Verify property ownership
     * @param propertyId Property ID
     * @param owner Address to verify
     * @return true if the address owns the property
     */
    function verifyOwnership(uint256 propertyId, address owner) 
        public 
        view 
        propertyExists(propertyId)
        returns (bool) 
    {
        return properties[propertyId].owner == owner;
    }

    /**
     * @dev Get property details
     * @param propertyId Property ID
     * @return Property details
     */
    function getProperty(uint256 propertyId) 
        public 
        view 
        propertyExists(propertyId)
        returns (Property memory) 
    {
        return properties[propertyId];
    }

    /**
     * @dev Get property by address
     * @param propertyAddress Property address
     * @return Property details
     */
    function getPropertyByAddress(string memory propertyAddress) 
        public 
        view 
        returns (Property memory) 
    {
        require(propertyAddressExists[propertyAddress], "Property address not found");
        uint256 propertyId = addressToPropertyId[propertyAddress];
        return properties[propertyId];
    }

    /**
     * @dev Check if property address is registered
     * @param propertyAddress Property address
     * @return true if registered
     */
    function isPropertyRegistered(string memory propertyAddress) public view returns (bool) {
        return propertyAddressExists[propertyAddress];
    }

    /**
     * @dev Get property ID by address
     * @param propertyAddress Property address
     * @return Property ID
     */
    function getPropertyIdByAddress(string memory propertyAddress) public view returns (uint256) {
        require(propertyAddressExists[propertyAddress], "Property address not found");
        return addressToPropertyId[propertyAddress];
    }

    /**
     * @dev Get all properties
     * @return Array of all properties
     */
    function getAllProperties() public view returns (Property[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allPropertyIds.length; i++) {
            if (properties[allPropertyIds[i]].exists) {
                count++;
            }
        }

        Property[] memory result = new Property[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allPropertyIds.length; i++) {
            if (properties[allPropertyIds[i]].exists) {
                result[index] = properties[allPropertyIds[i]];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get properties owned by an address
     * @param owner Owner address
     * @return Array of properties
     */
    function getPropertiesByOwner(address owner) public view returns (Property[] memory) {
        uint256[] memory propertyIds = ownerPropertyIds[owner];
        
        uint256 count = 0;
        for (uint256 i = 0; i < propertyIds.length; i++) {
            if (properties[propertyIds[i]].exists && properties[propertyIds[i]].owner == owner) {
                count++;
            }
        }

        Property[] memory result = new Property[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < propertyIds.length; i++) {
            Property memory property = properties[propertyIds[i]];
            if (property.exists && property.owner == owner) {
                result[index] = property;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get property transfer history
     * @param propertyId Property ID
     * @return Array of transfer records
     */
    function getPropertyTransferHistory(uint256 propertyId) 
        public 
        view 
        propertyExists(propertyId)
        returns (TransferRecord[] memory) 
    {
        return propertyTransferHistory[propertyId];
    }

    /**
     * @dev Get all transfers
     * @return Array of all transfer records
     */
    function getAllTransfers() public view returns (TransferRecord[] memory) {
        return allTransfers;
    }

    /**
     * @dev Get transfers involving an address
     * @param user User address
     * @return Array of transfer records
     */
    function getTransfersByAddress(address user) public view returns (TransferRecord[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTransfers.length; i++) {
            if (allTransfers[i].fromOwner == user || allTransfers[i].toOwner == user) {
                count++;
            }
        }

        TransferRecord[] memory result = new TransferRecord[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTransfers.length; i++) {
            if (allTransfers[i].fromOwner == user || allTransfers[i].toOwner == user) {
                result[index] = allTransfers[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get owner statistics
     * @param owner Owner address
     * @return OwnerStats structure
     */
    function getOwnerStats(address owner) public view returns (OwnerStats memory) {
        return ownerStats[owner];
    }

    /**
     * @dev Get properties by type
     * @param propertyType Property type
     * @return Array of properties
     */
    function getPropertiesByType(string memory propertyType) public view returns (Property[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allPropertyIds.length; i++) {
            Property memory property = properties[allPropertyIds[i]];
            if (property.exists && 
                keccak256(bytes(property.propertyType)) == keccak256(bytes(propertyType))) {
                count++;
            }
        }

        Property[] memory result = new Property[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allPropertyIds.length; i++) {
            Property memory property = properties[allPropertyIds[i]];
            if (property.exists && 
                keccak256(bytes(property.propertyType)) == keccak256(bytes(propertyType))) {
                result[index] = property;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total property count
     * @return Total number of properties
     */
    function getTotalPropertyCount() public view returns (uint256) {
        return propertyCounter;
    }

    /**
     * @dev Get total transfer count
     * @return Total number of transfers
     */
    function getTotalTransferCount() public view returns (uint256) {
        return transferCounter;
    }

    /**
     * @dev Get property count by owner
     * @param owner Owner address
     * @return Number of properties owned
     */
    function getPropertyCountByOwner(address owner) public view returns (uint256) {
        return ownerStats[owner].propertiesOwned;
    }

    /**
     * @dev Authorize a registrar
     * @param registrar Registrar address
     */
    function authorizeRegistrar(address registrar) public onlyRegistryOwner {
        require(registrar != address(0), "Invalid registrar address");
        require(!authorizedRegistrars[registrar], "Already authorized");

        authorizedRegistrars[registrar] = true;

        emit RegistrarAuthorized(registrar);
    }

    /**
     * @dev Revoke registrar authorization
     * @param registrar Registrar address
     */
    function revokeRegistrar(address registrar) public onlyRegistryOwner {
        require(registrar != registryOwner, "Cannot revoke registry owner");
        require(authorizedRegistrars[registrar], "Not authorized");

        authorizedRegistrars[registrar] = false;

        emit RegistrarRevoked(registrar);
    }

    /**
     * @dev Check if address is authorized registrar
     * @param registrar Address to check
     * @return true if authorized
     */
    function isAuthorizedRegistrar(address registrar) public view returns (bool) {
        return authorizedRegistrars[registrar];
    }

    /**
     * @dev Get recent properties
     * @param count Number of recent properties to retrieve
     * @return Array of recent properties
     */
    function getRecentProperties(uint256 count) public view returns (Property[] memory) {
        uint256 totalCount = 0;
        for (uint256 i = 0; i < allPropertyIds.length; i++) {
            if (properties[allPropertyIds[i]].exists) {
                totalCount++;
            }
        }

        uint256 resultCount = count > totalCount ? totalCount : count;
        Property[] memory result = new Property[](resultCount);
        uint256 index = 0;

        for (uint256 i = allPropertyIds.length; i > 0 && index < resultCount; i--) {
            if (properties[allPropertyIds[i - 1]].exists) {
                result[index] = properties[allPropertyIds[i - 1]];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get recent transfers
     * @param count Number of recent transfers to retrieve
     * @return Array of recent transfers
     */
    function getRecentTransfers(uint256 count) public view returns (TransferRecord[] memory) {
        uint256 totalCount = allTransfers.length;
        uint256 resultCount = count > totalCount ? totalCount : count;

        TransferRecord[] memory result = new TransferRecord[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = allTransfers[totalCount - 1 - i];
        }

        return result;
    }

    /**
     * @dev Transfer registry ownership
     * @param newOwner New registry owner address
     */
    function transferRegistryOwnership(address newOwner) public onlyRegistryOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != registryOwner, "Already the registry owner");

        authorizedRegistrars[registryOwner] = false;
        registryOwner = newOwner;
        authorizedRegistrars[newOwner] = true;
    }
}
