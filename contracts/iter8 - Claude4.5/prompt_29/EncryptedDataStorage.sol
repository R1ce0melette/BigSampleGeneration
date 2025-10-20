// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EncryptedDataStorage
 * @dev Contract that lets users store encrypted data hashes on-chain with ownership verification
 */
contract EncryptedDataStorage {
    // Data entry structure
    struct DataEntry {
        uint256 id;
        address owner;
        bytes32 dataHash;
        string encryptedMetadata;
        string description;
        uint256 timestamp;
        uint256 lastModified;
        bool isActive;
        uint256 version;
    }

    // Access permission structure
    struct AccessPermission {
        address grantedTo;
        uint256 dataId;
        uint256 grantedAt;
        uint256 expiryTime;
        bool isActive;
    }

    // User statistics
    struct UserStats {
        uint256 dataEntriesCreated;
        uint256 activeEntries;
        uint256 totalAccessGranted;
        uint256 totalAccessReceived;
    }

    // State variables
    address public owner;
    uint256 private dataIdCounter;
    uint256 private permissionIdCounter;

    mapping(uint256 => DataEntry) private dataEntries;
    mapping(address => uint256[]) private userDataEntries;
    mapping(uint256 => address[]) private dataAccessList;
    mapping(bytes32 => mapping(address => uint256[])) private hashToDataIds;
    mapping(uint256 => AccessPermission[]) private dataPermissions;
    mapping(address => mapping(uint256 => bool)) private hasAccess;
    mapping(address => UserStats) private userStats;
    mapping(bytes32 => bool) private hashExists;

    uint256[] private allDataIds;

    // Events
    event DataStored(uint256 indexed dataId, address indexed owner, bytes32 indexed dataHash, uint256 timestamp);
    event DataUpdated(uint256 indexed dataId, address indexed owner, bytes32 newDataHash, uint256 version);
    event DataDeactivated(uint256 indexed dataId, address indexed owner);
    event DataReactivated(uint256 indexed dataId, address indexed owner);
    event AccessGranted(uint256 indexed dataId, address indexed owner, address indexed grantedTo, uint256 expiryTime);
    event AccessRevoked(uint256 indexed dataId, address indexed owner, address indexed revokedFrom);
    event OwnershipTransferred(uint256 indexed dataId, address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyContractOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier dataExists(uint256 dataId) {
        require(dataId > 0 && dataId <= dataIdCounter, "Data entry does not exist");
        _;
    }

    modifier onlyDataOwner(uint256 dataId) {
        require(dataEntries[dataId].owner == msg.sender, "Not the data owner");
        _;
    }

    modifier onlyDataOwnerOrAccessGranted(uint256 dataId) {
        require(
            dataEntries[dataId].owner == msg.sender || hasAccess[msg.sender][dataId],
            "No access to this data"
        );
        _;
    }

    modifier dataIsActive(uint256 dataId) {
        require(dataEntries[dataId].isActive, "Data entry is not active");
        _;
    }

    constructor() {
        owner = msg.sender;
        dataIdCounter = 0;
        permissionIdCounter = 0;
    }

    /**
     * @dev Store encrypted data hash
     * @param dataHash Hash of the encrypted data
     * @param encryptedMetadata Encrypted metadata
     * @param description Description of the data
     * @return dataId ID of the stored data
     */
    function storeData(
        bytes32 dataHash,
        string memory encryptedMetadata,
        string memory description
    ) public returns (uint256) {
        require(dataHash != bytes32(0), "Invalid data hash");
        require(bytes(encryptedMetadata).length > 0, "Encrypted metadata cannot be empty");

        dataIdCounter++;
        uint256 dataId = dataIdCounter;

        DataEntry storage newEntry = dataEntries[dataId];
        newEntry.id = dataId;
        newEntry.owner = msg.sender;
        newEntry.dataHash = dataHash;
        newEntry.encryptedMetadata = encryptedMetadata;
        newEntry.description = description;
        newEntry.timestamp = block.timestamp;
        newEntry.lastModified = block.timestamp;
        newEntry.isActive = true;
        newEntry.version = 1;

        userDataEntries[msg.sender].push(dataId);
        hashToDataIds[dataHash][msg.sender].push(dataId);
        allDataIds.push(dataId);
        hashExists[dataHash] = true;

        // Update statistics
        userStats[msg.sender].dataEntriesCreated++;
        userStats[msg.sender].activeEntries++;

        emit DataStored(dataId, msg.sender, dataHash, block.timestamp);

        return dataId;
    }

    /**
     * @dev Batch store multiple data hashes
     * @param dataHashes Array of data hashes
     * @param encryptedMetadataArray Array of encrypted metadata
     * @param descriptions Array of descriptions
     * @return Array of data IDs
     */
    function batchStoreData(
        bytes32[] memory dataHashes,
        string[] memory encryptedMetadataArray,
        string[] memory descriptions
    ) public returns (uint256[] memory) {
        require(dataHashes.length > 0, "Empty arrays");
        require(
            dataHashes.length == encryptedMetadataArray.length &&
            dataHashes.length == descriptions.length,
            "Array length mismatch"
        );

        uint256[] memory dataIds = new uint256[](dataHashes.length);

        for (uint256 i = 0; i < dataHashes.length; i++) {
            dataIds[i] = storeData(dataHashes[i], encryptedMetadataArray[i], descriptions[i]);
        }

        return dataIds;
    }

    /**
     * @dev Update data hash and metadata
     * @param dataId Data ID to update
     * @param newDataHash New data hash
     * @param newEncryptedMetadata New encrypted metadata
     * @param newDescription New description
     */
    function updateData(
        uint256 dataId,
        bytes32 newDataHash,
        string memory newEncryptedMetadata,
        string memory newDescription
    ) public dataExists(dataId) onlyDataOwner(dataId) dataIsActive(dataId) {
        require(newDataHash != bytes32(0), "Invalid data hash");
        require(bytes(newEncryptedMetadata).length > 0, "Encrypted metadata cannot be empty");

        DataEntry storage entry = dataEntries[dataId];
        
        entry.dataHash = newDataHash;
        entry.encryptedMetadata = newEncryptedMetadata;
        entry.description = newDescription;
        entry.lastModified = block.timestamp;
        entry.version++;

        hashToDataIds[newDataHash][msg.sender].push(dataId);
        hashExists[newDataHash] = true;

        emit DataUpdated(dataId, msg.sender, newDataHash, entry.version);
    }

    /**
     * @dev Deactivate data entry
     * @param dataId Data ID to deactivate
     */
    function deactivateData(uint256 dataId) 
        public 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
        dataIsActive(dataId) 
    {
        dataEntries[dataId].isActive = false;
        userStats[msg.sender].activeEntries--;

        emit DataDeactivated(dataId, msg.sender);
    }

    /**
     * @dev Reactivate data entry
     * @param dataId Data ID to reactivate
     */
    function reactivateData(uint256 dataId) 
        public 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
    {
        require(!dataEntries[dataId].isActive, "Data entry is already active");

        dataEntries[dataId].isActive = true;
        dataEntries[dataId].lastModified = block.timestamp;
        userStats[msg.sender].activeEntries++;

        emit DataReactivated(dataId, msg.sender);
    }

    /**
     * @dev Grant access to data
     * @param dataId Data ID
     * @param grantTo Address to grant access to
     * @param expiryTime Expiry timestamp (0 for no expiry)
     */
    function grantAccess(uint256 dataId, address grantTo, uint256 expiryTime) 
        public 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
        dataIsActive(dataId) 
    {
        require(grantTo != address(0), "Invalid address");
        require(grantTo != msg.sender, "Cannot grant access to yourself");
        require(!hasAccess[grantTo][dataId], "Access already granted");
        
        if (expiryTime > 0) {
            require(expiryTime > block.timestamp, "Expiry time must be in the future");
        }

        AccessPermission memory permission = AccessPermission({
            grantedTo: grantTo,
            dataId: dataId,
            grantedAt: block.timestamp,
            expiryTime: expiryTime,
            isActive: true
        });

        dataPermissions[dataId].push(permission);
        dataAccessList[dataId].push(grantTo);
        hasAccess[grantTo][dataId] = true;

        // Update statistics
        userStats[msg.sender].totalAccessGranted++;
        userStats[grantTo].totalAccessReceived++;

        emit AccessGranted(dataId, msg.sender, grantTo, expiryTime);
    }

    /**
     * @dev Revoke access to data
     * @param dataId Data ID
     * @param revokeFrom Address to revoke access from
     */
    function revokeAccess(uint256 dataId, address revokeFrom) 
        public 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
    {
        require(hasAccess[revokeFrom][dataId], "No access granted");

        hasAccess[revokeFrom][dataId] = false;

        // Update permission status
        AccessPermission[] storage permissions = dataPermissions[dataId];
        for (uint256 i = 0; i < permissions.length; i++) {
            if (permissions[i].grantedTo == revokeFrom && permissions[i].isActive) {
                permissions[i].isActive = false;
            }
        }

        emit AccessRevoked(dataId, msg.sender, revokeFrom);
    }

    /**
     * @dev Transfer data ownership
     * @param dataId Data ID
     * @param newOwner New owner address
     */
    function transferDataOwnership(uint256 dataId, address newOwner) 
        public 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
        dataIsActive(dataId) 
    {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != msg.sender, "Already the owner");

        address previousOwner = msg.sender;
        dataEntries[dataId].owner = newOwner;
        dataEntries[dataId].lastModified = block.timestamp;

        // Update user data entries
        userDataEntries[newOwner].push(dataId);

        // Update statistics
        userStats[previousOwner].activeEntries--;
        userStats[newOwner].activeEntries++;

        emit OwnershipTransferred(dataId, previousOwner, newOwner);
    }

    /**
     * @dev Verify data ownership
     * @param dataId Data ID
     * @param claimedOwner Address claiming ownership
     * @return true if verified
     */
    function verifyOwnership(uint256 dataId, address claimedOwner) 
        public 
        view 
        dataExists(dataId) 
        returns (bool) 
    {
        return dataEntries[dataId].owner == claimedOwner;
    }

    /**
     * @dev Verify data hash
     * @param dataId Data ID
     * @param dataHash Hash to verify
     * @return true if hash matches
     */
    function verifyDataHash(uint256 dataId, bytes32 dataHash) 
        public 
        view 
        dataExists(dataId) 
        returns (bool) 
    {
        return dataEntries[dataId].dataHash == dataHash;
    }

    /**
     * @dev Check if user has access to data
     * @param dataId Data ID
     * @param user User address
     * @return true if has access
     */
    function checkAccess(uint256 dataId, address user) 
        public 
        view 
        dataExists(dataId) 
        returns (bool) 
    {
        if (dataEntries[dataId].owner == user) {
            return true;
        }

        if (!hasAccess[user][dataId]) {
            return false;
        }

        // Check if access is expired
        AccessPermission[] memory permissions = dataPermissions[dataId];
        for (uint256 i = 0; i < permissions.length; i++) {
            if (permissions[i].grantedTo == user && permissions[i].isActive) {
                if (permissions[i].expiryTime == 0 || block.timestamp <= permissions[i].expiryTime) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * @dev Get data entry
     * @param dataId Data ID
     * @return DataEntry details
     */
    function getDataEntry(uint256 dataId) 
        public 
        view 
        dataExists(dataId) 
        onlyDataOwnerOrAccessGranted(dataId) 
        returns (DataEntry memory) 
    {
        return dataEntries[dataId];
    }

    /**
     * @dev Get data hash (only owner or granted access)
     * @param dataId Data ID
     * @return Data hash
     */
    function getDataHash(uint256 dataId) 
        public 
        view 
        dataExists(dataId) 
        onlyDataOwnerOrAccessGranted(dataId) 
        returns (bytes32) 
    {
        return dataEntries[dataId].dataHash;
    }

    /**
     * @dev Get encrypted metadata (only owner or granted access)
     * @param dataId Data ID
     * @return Encrypted metadata
     */
    function getEncryptedMetadata(uint256 dataId) 
        public 
        view 
        dataExists(dataId) 
        onlyDataOwnerOrAccessGranted(dataId) 
        returns (string memory) 
    {
        return dataEntries[dataId].encryptedMetadata;
    }

    /**
     * @dev Get data owner
     * @param dataId Data ID
     * @return Owner address
     */
    function getDataOwner(uint256 dataId) 
        public 
        view 
        dataExists(dataId) 
        returns (address) 
    {
        return dataEntries[dataId].owner;
    }

    /**
     * @dev Get user data entries
     * @param user User address
     * @return Array of data IDs
     */
    function getUserDataEntries(address user) public view returns (uint256[] memory) {
        return userDataEntries[user];
    }

    /**
     * @dev Get data IDs by hash
     * @param dataHash Data hash
     * @param user User address
     * @return Array of data IDs
     */
    function getDataIdsByHash(bytes32 dataHash, address user) public view returns (uint256[] memory) {
        return hashToDataIds[dataHash][user];
    }

    /**
     * @dev Get access permissions for data
     * @param dataId Data ID
     * @return Array of access permissions
     */
    function getDataPermissions(uint256 dataId) 
        public 
        view 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
        returns (AccessPermission[] memory) 
    {
        return dataPermissions[dataId];
    }

    /**
     * @dev Get active permissions for data
     * @param dataId Data ID
     * @return Array of active access permissions
     */
    function getActivePermissions(uint256 dataId) 
        public 
        view 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
        returns (AccessPermission[] memory) 
    {
        AccessPermission[] memory allPermissions = dataPermissions[dataId];
        uint256 count = 0;

        for (uint256 i = 0; i < allPermissions.length; i++) {
            if (allPermissions[i].isActive) {
                if (allPermissions[i].expiryTime == 0 || block.timestamp <= allPermissions[i].expiryTime) {
                    count++;
                }
            }
        }

        AccessPermission[] memory result = new AccessPermission[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allPermissions.length; i++) {
            AccessPermission memory perm = allPermissions[i];
            if (perm.isActive) {
                if (perm.expiryTime == 0 || block.timestamp <= perm.expiryTime) {
                    result[index] = perm;
                    index++;
                }
            }
        }

        return result;
    }

    /**
     * @dev Get addresses with access to data
     * @param dataId Data ID
     * @return Array of addresses
     */
    function getAccessList(uint256 dataId) 
        public 
        view 
        dataExists(dataId) 
        onlyDataOwner(dataId) 
        returns (address[] memory) 
    {
        return dataAccessList[dataId];
    }

    /**
     * @dev Get all data entries
     * @return Array of all data entries (only public info)
     */
    function getAllDataIds() public view returns (uint256[] memory) {
        return allDataIds;
    }

    /**
     * @dev Get active data entries for user
     * @param user User address
     * @return Array of active data entries
     */
    function getActiveUserDataEntries(address user) public view returns (uint256[] memory) {
        uint256[] memory userEntries = userDataEntries[user];
        uint256 count = 0;

        for (uint256 i = 0; i < userEntries.length; i++) {
            if (dataEntries[userEntries[i]].isActive) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < userEntries.length; i++) {
            uint256 dataId = userEntries[i];
            if (dataEntries[dataId].isActive) {
                result[index] = dataId;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return UserStats details
     */
    function getUserStats(address user) public view returns (UserStats memory) {
        return userStats[user];
    }

    /**
     * @dev Check if hash exists in system
     * @param dataHash Data hash to check
     * @return true if exists
     */
    function doesHashExist(bytes32 dataHash) public view returns (bool) {
        return hashExists[dataHash];
    }

    /**
     * @dev Get total data entries count
     * @return Total count
     */
    function getTotalDataEntries() public view returns (uint256) {
        return dataIdCounter;
    }

    /**
     * @dev Get total active entries count
     * @return Active count
     */
    function getTotalActiveEntries() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allDataIds.length; i++) {
            if (dataEntries[allDataIds[i]].isActive) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Transfer contract ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyContractOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }
}
