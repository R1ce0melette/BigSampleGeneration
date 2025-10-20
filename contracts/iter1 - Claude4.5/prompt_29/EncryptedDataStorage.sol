// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EncryptedDataStorage
 * @dev A contract that lets users store encrypted data hashes on-chain with ownership verification
 */
contract EncryptedDataStorage {
    struct DataRecord {
        uint256 id;
        address owner;
        bytes32 dataHash;
        string metadata;
        uint256 timestamp;
        bool isActive;
        uint256 version;
    }
    
    struct AccessGrant {
        address grantee;
        uint256 grantedAt;
        uint256 expiresAt;
        bool isActive;
    }
    
    uint256 private recordCounter;
    mapping(uint256 => DataRecord) public dataRecords;
    mapping(address => uint256[]) private ownerRecords;
    mapping(bytes32 => uint256[]) private hashToRecordIds;
    mapping(uint256 => mapping(address => AccessGrant)) public accessGrants;
    mapping(uint256 => address[]) private recordGrantees;
    
    event DataStored(
        uint256 indexed recordId,
        address indexed owner,
        bytes32 indexed dataHash,
        uint256 timestamp
    );
    
    event DataUpdated(
        uint256 indexed recordId,
        bytes32 indexed newDataHash,
        uint256 newVersion,
        uint256 timestamp
    );
    
    event DataDeleted(
        uint256 indexed recordId,
        address indexed owner,
        uint256 timestamp
    );
    
    event AccessGranted(
        uint256 indexed recordId,
        address indexed owner,
        address indexed grantee,
        uint256 expiresAt
    );
    
    event AccessRevoked(
        uint256 indexed recordId,
        address indexed owner,
        address indexed grantee
    );
    
    event OwnershipTransferred(
        uint256 indexed recordId,
        address indexed previousOwner,
        address indexed newOwner
    );
    
    modifier onlyRecordOwner(uint256 recordId) {
        require(dataRecords[recordId].owner == msg.sender, "Not the record owner");
        _;
    }
    
    modifier recordExists(uint256 recordId) {
        require(recordId > 0 && recordId <= recordCounter, "Record does not exist");
        require(dataRecords[recordId].isActive, "Record has been deleted");
        _;
    }
    
    /**
     * @dev Store encrypted data hash on-chain
     * @param dataHash The hash of the encrypted data
     * @param metadata Optional metadata about the data
     * @return recordId The ID of the stored record
     */
    function storeData(bytes32 dataHash, string memory metadata) external returns (uint256) {
        require(dataHash != bytes32(0), "Invalid data hash");
        
        recordCounter++;
        uint256 recordId = recordCounter;
        
        dataRecords[recordId] = DataRecord({
            id: recordId,
            owner: msg.sender,
            dataHash: dataHash,
            metadata: metadata,
            timestamp: block.timestamp,
            isActive: true,
            version: 1
        });
        
        ownerRecords[msg.sender].push(recordId);
        hashToRecordIds[dataHash].push(recordId);
        
        emit DataStored(recordId, msg.sender, dataHash, block.timestamp);
        
        return recordId;
    }
    
    /**
     * @dev Update an existing data record
     * @param recordId The ID of the record to update
     * @param newDataHash The new data hash
     * @param newMetadata The new metadata
     */
    function updateData(
        uint256 recordId,
        bytes32 newDataHash,
        string memory newMetadata
    ) external recordExists(recordId) onlyRecordOwner(recordId) {
        require(newDataHash != bytes32(0), "Invalid data hash");
        
        DataRecord storage record = dataRecords[recordId];
        
        record.dataHash = newDataHash;
        record.metadata = newMetadata;
        record.timestamp = block.timestamp;
        record.version++;
        
        hashToRecordIds[newDataHash].push(recordId);
        
        emit DataUpdated(recordId, newDataHash, record.version, block.timestamp);
    }
    
    /**
     * @dev Delete a data record (soft delete)
     * @param recordId The ID of the record to delete
     */
    function deleteData(uint256 recordId) 
        external 
        recordExists(recordId) 
        onlyRecordOwner(recordId) 
    {
        dataRecords[recordId].isActive = false;
        
        emit DataDeleted(recordId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Grant access to a data record for another address
     * @param recordId The ID of the record
     * @param grantee The address to grant access to
     * @param duration Duration of access in seconds (0 for permanent)
     */
    function grantAccess(
        uint256 recordId,
        address grantee,
        uint256 duration
    ) external recordExists(recordId) onlyRecordOwner(recordId) {
        require(grantee != address(0), "Invalid grantee address");
        require(grantee != msg.sender, "Cannot grant access to yourself");
        
        uint256 expiresAt = duration == 0 ? 0 : block.timestamp + duration;
        
        // Check if this is a new grantee
        if (!accessGrants[recordId][grantee].isActive && 
            accessGrants[recordId][grantee].grantedAt == 0) {
            recordGrantees[recordId].push(grantee);
        }
        
        accessGrants[recordId][grantee] = AccessGrant({
            grantee: grantee,
            grantedAt: block.timestamp,
            expiresAt: expiresAt,
            isActive: true
        });
        
        emit AccessGranted(recordId, msg.sender, grantee, expiresAt);
    }
    
    /**
     * @dev Revoke access to a data record
     * @param recordId The ID of the record
     * @param grantee The address to revoke access from
     */
    function revokeAccess(
        uint256 recordId,
        address grantee
    ) external recordExists(recordId) onlyRecordOwner(recordId) {
        require(accessGrants[recordId][grantee].isActive, "No active access grant");
        
        accessGrants[recordId][grantee].isActive = false;
        
        emit AccessRevoked(recordId, msg.sender, grantee);
    }
    
    /**
     * @dev Transfer ownership of a data record
     * @param recordId The ID of the record
     * @param newOwner The address of the new owner
     */
    function transferOwnership(
        uint256 recordId,
        address newOwner
    ) external recordExists(recordId) onlyRecordOwner(recordId) {
        require(newOwner != address(0), "Invalid new owner");
        require(newOwner != msg.sender, "Already the owner");
        
        address previousOwner = dataRecords[recordId].owner;
        dataRecords[recordId].owner = newOwner;
        
        // Add to new owner's records
        ownerRecords[newOwner].push(recordId);
        
        // Remove all access grants on ownership transfer
        address[] storage grantees = recordGrantees[recordId];
        for (uint256 i = 0; i < grantees.length; i++) {
            accessGrants[recordId][grantees[i]].isActive = false;
        }
        
        emit OwnershipTransferred(recordId, previousOwner, newOwner);
    }
    
    /**
     * @dev Verify ownership of a data record
     * @param recordId The ID of the record
     * @param claimedOwner The address claiming ownership
     * @return Whether the claimed owner is the actual owner
     */
    function verifyOwnership(uint256 recordId, address claimedOwner) 
        external 
        view 
        recordExists(recordId) 
        returns (bool) 
    {
        return dataRecords[recordId].owner == claimedOwner;
    }
    
    /**
     * @dev Check if an address has access to a record
     * @param recordId The ID of the record
     * @param user The address to check
     * @return Whether the user has access
     */
    function hasAccess(uint256 recordId, address user) 
        external 
        view 
        recordExists(recordId) 
        returns (bool) 
    {
        // Owner always has access
        if (dataRecords[recordId].owner == user) {
            return true;
        }
        
        AccessGrant memory grant = accessGrants[recordId][user];
        
        if (!grant.isActive) {
            return false;
        }
        
        // Check if access has expired (0 means permanent)
        if (grant.expiresAt != 0 && block.timestamp > grant.expiresAt) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @dev Get data record details
     * @param recordId The ID of the record
     * @return id Record ID
     * @return owner Owner address
     * @return dataHash The data hash
     * @return metadata The metadata
     * @return timestamp When it was created/updated
     * @return isActive Whether the record is active
     * @return version Version number
     */
    function getDataRecord(uint256 recordId) 
        external 
        view 
        recordExists(recordId) 
        returns (
            uint256 id,
            address owner,
            bytes32 dataHash,
            string memory metadata,
            uint256 timestamp,
            bool isActive,
            uint256 version
        ) 
    {
        DataRecord memory record = dataRecords[recordId];
        return (
            record.id,
            record.owner,
            record.dataHash,
            record.metadata,
            record.timestamp,
            record.isActive,
            record.version
        );
    }
    
    /**
     * @dev Get the data hash for a record (only if caller has access)
     * @param recordId The ID of the record
     * @return The data hash
     */
    function getDataHash(uint256 recordId) 
        external 
        view 
        recordExists(recordId) 
        returns (bytes32) 
    {
        // Check if caller has access
        DataRecord memory record = dataRecords[recordId];
        
        if (record.owner == msg.sender) {
            return record.dataHash;
        }
        
        AccessGrant memory grant = accessGrants[recordId][msg.sender];
        require(grant.isActive, "No access to this record");
        
        if (grant.expiresAt != 0) {
            require(block.timestamp <= grant.expiresAt, "Access has expired");
        }
        
        return record.dataHash;
    }
    
    /**
     * @dev Get all records owned by an address
     * @param owner The owner's address
     * @return Array of record IDs
     */
    function getRecordsByOwner(address owner) external view returns (uint256[] memory) {
        return ownerRecords[owner];
    }
    
    /**
     * @dev Get active records owned by an address
     * @param owner The owner's address
     * @return Array of active record IDs
     */
    function getActiveRecordsByOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory allRecords = ownerRecords[owner];
        uint256 activeCount = 0;
        
        // Count active records
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (dataRecords[allRecords[i]].isActive) {
                activeCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeRecords = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (dataRecords[allRecords[i]].isActive) {
                activeRecords[index] = allRecords[i];
                index++;
            }
        }
        
        return activeRecords;
    }
    
    /**
     * @dev Get all records with a specific data hash
     * @param dataHash The data hash to search for
     * @return Array of record IDs
     */
    function getRecordsByHash(bytes32 dataHash) external view returns (uint256[] memory) {
        return hashToRecordIds[dataHash];
    }
    
    /**
     * @dev Get all addresses with access to a record
     * @param recordId The ID of the record
     * @return Array of addresses with access
     */
    function getGrantees(uint256 recordId) 
        external 
        view 
        recordExists(recordId) 
        returns (address[] memory) 
    {
        return recordGrantees[recordId];
    }
    
    /**
     * @dev Get active grantees for a record
     * @param recordId The ID of the record
     * @return Array of addresses with active access
     */
    function getActiveGrantees(uint256 recordId) 
        external 
        view 
        recordExists(recordId) 
        returns (address[] memory) 
    {
        address[] memory allGrantees = recordGrantees[recordId];
        uint256 activeCount = 0;
        
        // Count active grantees
        for (uint256 i = 0; i < allGrantees.length; i++) {
            AccessGrant memory grant = accessGrants[recordId][allGrantees[i]];
            if (grant.isActive && (grant.expiresAt == 0 || block.timestamp <= grant.expiresAt)) {
                activeCount++;
            }
        }
        
        // Create array and populate
        address[] memory activeGranteesList = new address[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allGrantees.length; i++) {
            AccessGrant memory grant = accessGrants[recordId][allGrantees[i]];
            if (grant.isActive && (grant.expiresAt == 0 || block.timestamp <= grant.expiresAt)) {
                activeGranteesList[index] = allGrantees[i];
                index++;
            }
        }
        
        return activeGranteesList;
    }
    
    /**
     * @dev Get access grant details
     * @param recordId The ID of the record
     * @param grantee The address of the grantee
     * @return granteeAddress The grantee's address
     * @return grantedAt When access was granted
     * @return expiresAt When access expires (0 for permanent)
     * @return isActive Whether the grant is active
     */
    function getAccessGrant(uint256 recordId, address grantee) 
        external 
        view 
        recordExists(recordId) 
        returns (
            address granteeAddress,
            uint256 grantedAt,
            uint256 expiresAt,
            bool isActive
        ) 
    {
        AccessGrant memory grant = accessGrants[recordId][grantee];
        return (grant.grantee, grant.grantedAt, grant.expiresAt, grant.isActive);
    }
    
    /**
     * @dev Get total number of records
     * @return The total count
     */
    function getTotalRecords() external view returns (uint256) {
        return recordCounter;
    }
    
    /**
     * @dev Get total number of active records
     * @return The count of active records
     */
    function getTotalActiveRecords() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= recordCounter; i++) {
            if (dataRecords[i].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Check if a record exists and is active
     * @param recordId The ID of the record
     * @return Whether the record exists and is active
     */
    function isRecordActive(uint256 recordId) external view returns (bool) {
        if (recordId == 0 || recordId > recordCounter) {
            return false;
        }
        return dataRecords[recordId].isActive;
    }
}
