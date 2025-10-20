// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EncryptedDataStorage
 * @dev Contract that lets users store encrypted data hashes on-chain with ownership verification
 */
contract EncryptedDataStorage {
    // Data record structure
    struct DataRecord {
        bytes32 dataHash;
        address owner;
        uint256 timestamp;
        string description;
        bool isPublic;
        bool exists;
    }

    // Access permission structure
    struct AccessPermission {
        address grantedTo;
        uint256 grantedAt;
        uint256 expiresAt; // 0 for never expires
        bool isActive;
    }

    // State variables
    address public contractOwner;
    uint256 private recordIdCounter;

    // Mappings
    mapping(uint256 => DataRecord) private dataRecords;
    mapping(address => uint256[]) private ownerRecords;
    mapping(uint256 => mapping(address => AccessPermission)) private accessPermissions;
    mapping(uint256 => address[]) private authorizedUsers;
    mapping(bytes32 => uint256[]) private hashToRecordIds;

    // Events
    event DataStored(uint256 indexed recordId, address indexed owner, bytes32 dataHash, uint256 timestamp);
    event DataUpdated(uint256 indexed recordId, bytes32 oldHash, bytes32 newHash, uint256 timestamp);
    event DataDeleted(uint256 indexed recordId, address indexed owner, uint256 timestamp);
    event AccessGranted(uint256 indexed recordId, address indexed owner, address indexed grantedTo, uint256 expiresAt);
    event AccessRevoked(uint256 indexed recordId, address indexed owner, address indexed revokedFrom);
    event OwnershipTransferred(uint256 indexed recordId, address indexed previousOwner, address indexed newOwner);
    event VisibilityChanged(uint256 indexed recordId, bool isPublic);

    // Modifiers
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Not contract owner");
        _;
    }

    modifier recordExists(uint256 recordId) {
        require(dataRecords[recordId].exists, "Record does not exist");
        _;
    }

    modifier onlyRecordOwner(uint256 recordId) {
        require(dataRecords[recordId].owner == msg.sender, "Not record owner");
        _;
    }

    modifier hasAccess(uint256 recordId) {
        require(_hasAccess(msg.sender, recordId), "Access denied");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
        recordIdCounter = 1;
    }

    /**
     * @dev Store encrypted data hash
     * @param dataHash Hash of encrypted data
     * @param description Description of the data
     * @param isPublic Whether the data is publicly accessible
     * @return recordId ID of the stored record
     */
    function storeData(
        bytes32 dataHash,
        string memory description,
        bool isPublic
    ) public returns (uint256) {
        require(dataHash != bytes32(0), "Invalid data hash");

        uint256 recordId = recordIdCounter;
        recordIdCounter++;

        dataRecords[recordId] = DataRecord({
            dataHash: dataHash,
            owner: msg.sender,
            timestamp: block.timestamp,
            description: description,
            isPublic: isPublic,
            exists: true
        });

        ownerRecords[msg.sender].push(recordId);
        hashToRecordIds[dataHash].push(recordId);

        emit DataStored(recordId, msg.sender, dataHash, block.timestamp);

        return recordId;
    }

    /**
     * @dev Update data hash
     * @param recordId Record ID to update
     * @param newDataHash New data hash
     * @param newDescription New description
     */
    function updateData(
        uint256 recordId,
        bytes32 newDataHash,
        string memory newDescription
    ) public recordExists(recordId) onlyRecordOwner(recordId) {
        require(newDataHash != bytes32(0), "Invalid data hash");

        bytes32 oldHash = dataRecords[recordId].dataHash;
        dataRecords[recordId].dataHash = newDataHash;
        dataRecords[recordId].description = newDescription;
        dataRecords[recordId].timestamp = block.timestamp;

        hashToRecordIds[newDataHash].push(recordId);

        emit DataUpdated(recordId, oldHash, newDataHash, block.timestamp);
    }

    /**
     * @dev Delete data record
     * @param recordId Record ID to delete
     */
    function deleteData(uint256 recordId) public recordExists(recordId) onlyRecordOwner(recordId) {
        delete dataRecords[recordId];

        emit DataDeleted(recordId, msg.sender, block.timestamp);
    }

    /**
     * @dev Grant access to another user
     * @param recordId Record ID
     * @param user Address to grant access to
     * @param expiresAt Expiration timestamp (0 for never)
     */
    function grantAccess(
        uint256 recordId,
        address user,
        uint256 expiresAt
    ) public recordExists(recordId) onlyRecordOwner(recordId) {
        require(user != address(0), "Invalid user address");
        require(user != msg.sender, "Cannot grant access to yourself");
        require(expiresAt == 0 || expiresAt > block.timestamp, "Invalid expiration time");

        if (!accessPermissions[recordId][user].isActive) {
            authorizedUsers[recordId].push(user);
        }

        accessPermissions[recordId][user] = AccessPermission({
            grantedTo: user,
            grantedAt: block.timestamp,
            expiresAt: expiresAt,
            isActive: true
        });

        emit AccessGranted(recordId, msg.sender, user, expiresAt);
    }

    /**
     * @dev Revoke access from a user
     * @param recordId Record ID
     * @param user Address to revoke access from
     */
    function revokeAccess(
        uint256 recordId,
        address user
    ) public recordExists(recordId) onlyRecordOwner(recordId) {
        require(accessPermissions[recordId][user].isActive, "User does not have access");

        accessPermissions[recordId][user].isActive = false;

        emit AccessRevoked(recordId, msg.sender, user);
    }

    /**
     * @dev Transfer ownership of a record
     * @param recordId Record ID
     * @param newOwner New owner address
     */
    function transferOwnership(
        uint256 recordId,
        address newOwner
    ) public recordExists(recordId) onlyRecordOwner(recordId) {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != msg.sender, "Already the owner");

        address previousOwner = dataRecords[recordId].owner;
        dataRecords[recordId].owner = newOwner;

        ownerRecords[newOwner].push(recordId);

        emit OwnershipTransferred(recordId, previousOwner, newOwner);
    }

    /**
     * @dev Change visibility of a record
     * @param recordId Record ID
     * @param isPublic New visibility status
     */
    function setVisibility(
        uint256 recordId,
        bool isPublic
    ) public recordExists(recordId) onlyRecordOwner(recordId) {
        dataRecords[recordId].isPublic = isPublic;

        emit VisibilityChanged(recordId, isPublic);
    }

    /**
     * @dev Batch grant access to multiple users
     * @param recordId Record ID
     * @param users Array of addresses to grant access to
     * @param expiresAt Expiration timestamp (0 for never)
     */
    function batchGrantAccess(
        uint256 recordId,
        address[] memory users,
        uint256 expiresAt
    ) public recordExists(recordId) onlyRecordOwner(recordId) {
        require(users.length > 0, "Empty users array");
        require(expiresAt == 0 || expiresAt > block.timestamp, "Invalid expiration time");

        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] != address(0) && users[i] != msg.sender) {
                if (!accessPermissions[recordId][users[i]].isActive) {
                    authorizedUsers[recordId].push(users[i]);
                }

                accessPermissions[recordId][users[i]] = AccessPermission({
                    grantedTo: users[i],
                    grantedAt: block.timestamp,
                    expiresAt: expiresAt,
                    isActive: true
                });

                emit AccessGranted(recordId, msg.sender, users[i], expiresAt);
            }
        }
    }

    /**
     * @dev Internal function to check if a user has access to a record
     * @param user User address
     * @param recordId Record ID
     * @return true if user has access
     */
    function _hasAccess(address user, uint256 recordId) private view returns (bool) {
        if (!dataRecords[recordId].exists) {
            return false;
        }

        // Owner always has access
        if (dataRecords[recordId].owner == user) {
            return true;
        }

        // Public records are accessible to everyone
        if (dataRecords[recordId].isPublic) {
            return true;
        }

        // Check if user has been granted access
        AccessPermission memory permission = accessPermissions[recordId][user];
        if (permission.isActive) {
            // Check if permission has expired
            if (permission.expiresAt == 0 || permission.expiresAt > block.timestamp) {
                return true;
            }
        }

        return false;
    }

    // View Functions

    /**
     * @dev Get data record
     * @param recordId Record ID
     * @return dataHash Data hash
     * @return owner Owner address
     * @return timestamp Creation timestamp
     * @return description Description
     * @return isPublic Visibility status
     */
    function getDataRecord(uint256 recordId) 
        public 
        view 
        recordExists(recordId) 
        hasAccess(recordId)
        returns (
            bytes32 dataHash,
            address owner,
            uint256 timestamp,
            string memory description,
            bool isPublic
        ) 
    {
        DataRecord memory record = dataRecords[recordId];
        return (record.dataHash, record.owner, record.timestamp, record.description, record.isPublic);
    }

    /**
     * @dev Get data hash only
     * @param recordId Record ID
     * @return Data hash
     */
    function getDataHash(uint256 recordId) 
        public 
        view 
        recordExists(recordId) 
        hasAccess(recordId)
        returns (bytes32) 
    {
        return dataRecords[recordId].dataHash;
    }

    /**
     * @dev Get record owner
     * @param recordId Record ID
     * @return Owner address
     */
    function getRecordOwner(uint256 recordId) 
        public 
        view 
        recordExists(recordId) 
        returns (address) 
    {
        return dataRecords[recordId].owner;
    }

    /**
     * @dev Check if a user has access to a record
     * @param user User address
     * @param recordId Record ID
     * @return true if user has access
     */
    function hasAccessToRecord(address user, uint256 recordId) 
        public 
        view 
        recordExists(recordId) 
        returns (bool) 
    {
        return _hasAccess(user, recordId);
    }

    /**
     * @dev Get all records owned by an address
     * @param owner Owner address
     * @return Array of record IDs
     */
    function getRecordsByOwner(address owner) public view returns (uint256[] memory) {
        return ownerRecords[owner];
    }

    /**
     * @dev Get access permission details
     * @param recordId Record ID
     * @param user User address
     * @return grantedAt Grant timestamp
     * @return expiresAt Expiration timestamp
     * @return isActive Active status
     */
    function getAccessPermission(uint256 recordId, address user) 
        public 
        view 
        recordExists(recordId)
        returns (
            uint256 grantedAt,
            uint256 expiresAt,
            bool isActive
        ) 
    {
        AccessPermission memory permission = accessPermissions[recordId][user];
        return (permission.grantedAt, permission.expiresAt, permission.isActive);
    }

    /**
     * @dev Get all users with access to a record
     * @param recordId Record ID
     * @return Array of addresses
     */
    function getAuthorizedUsers(uint256 recordId) 
        public 
        view 
        recordExists(recordId) 
        onlyRecordOwner(recordId)
        returns (address[] memory) 
    {
        return authorizedUsers[recordId];
    }

    /**
     * @dev Get active authorized users for a record
     * @param recordId Record ID
     * @return Array of addresses with active access
     */
    function getActiveAuthorizedUsers(uint256 recordId) 
        public 
        view 
        recordExists(recordId) 
        onlyRecordOwner(recordId)
        returns (address[] memory) 
    {
        address[] memory allUsers = authorizedUsers[recordId];
        uint256 activeCount = 0;

        // Count active users
        for (uint256 i = 0; i < allUsers.length; i++) {
            AccessPermission memory permission = accessPermissions[recordId][allUsers[i]];
            if (permission.isActive && (permission.expiresAt == 0 || permission.expiresAt > block.timestamp)) {
                activeCount++;
            }
        }

        // Build result array
        address[] memory activeUsers = new address[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allUsers.length; i++) {
            AccessPermission memory permission = accessPermissions[recordId][allUsers[i]];
            if (permission.isActive && (permission.expiresAt == 0 || permission.expiresAt > block.timestamp)) {
                activeUsers[index] = allUsers[i];
                index++;
            }
        }

        return activeUsers;
    }

    /**
     * @dev Get records by data hash
     * @param dataHash Data hash to search for
     * @return Array of record IDs
     */
    function getRecordsByHash(bytes32 dataHash) public view returns (uint256[] memory) {
        return hashToRecordIds[dataHash];
    }

    /**
     * @dev Get total number of records
     * @return Total record count
     */
    function getTotalRecords() public view returns (uint256) {
        return recordIdCounter - 1;
    }

    /**
     * @dev Check if a record exists
     * @param recordId Record ID
     * @return true if exists
     */
    function recordExistsCheck(uint256 recordId) public view returns (bool) {
        return dataRecords[recordId].exists;
    }

    /**
     * @dev Check if a record is public
     * @param recordId Record ID
     * @return true if public
     */
    function isPublicRecord(uint256 recordId) public view recordExists(recordId) returns (bool) {
        return dataRecords[recordId].isPublic;
    }

    /**
     * @dev Get all public records
     * @return Array of public record IDs
     */
    function getPublicRecords() public view returns (uint256[] memory) {
        uint256 publicCount = 0;
        
        // Count public records
        for (uint256 i = 1; i < recordIdCounter; i++) {
            if (dataRecords[i].exists && dataRecords[i].isPublic) {
                publicCount++;
            }
        }

        // Build result array
        uint256[] memory publicRecords = new uint256[](publicCount);
        uint256 index = 0;
        for (uint256 i = 1; i < recordIdCounter; i++) {
            if (dataRecords[i].exists && dataRecords[i].isPublic) {
                publicRecords[index] = i;
                index++;
            }
        }

        return publicRecords;
    }

    /**
     * @dev Get records accessible by a user
     * @param user User address
     * @return Array of accessible record IDs
     */
    function getAccessibleRecords(address user) public view returns (uint256[] memory) {
        uint256 accessibleCount = 0;
        
        // Count accessible records
        for (uint256 i = 1; i < recordIdCounter; i++) {
            if (dataRecords[i].exists && _hasAccess(user, i)) {
                accessibleCount++;
            }
        }

        // Build result array
        uint256[] memory accessibleRecords = new uint256[](accessibleCount);
        uint256 index = 0;
        for (uint256 i = 1; i < recordIdCounter; i++) {
            if (dataRecords[i].exists && _hasAccess(user, i)) {
                accessibleRecords[index] = i;
                index++;
            }
        }

        return accessibleRecords;
    }

    /**
     * @dev Get number of records owned by an address
     * @param owner Owner address
     * @return Count of owned records
     */
    function getRecordCountByOwner(address owner) public view returns (uint256) {
        return ownerRecords[owner].length;
    }
}
