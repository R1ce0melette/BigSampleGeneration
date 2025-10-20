// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStorage {
    struct DataRecord {
        uint256 id;
        address owner;
        bytes32 dataHash;
        string description;
        uint256 timestamp;
        bool exists;
    }
    
    uint256 public recordCount;
    mapping(uint256 => DataRecord) public records;
    mapping(address => uint256[]) public ownerRecords;
    mapping(bytes32 => uint256) public hashToRecordId;
    
    // Events
    event DataStored(uint256 indexed recordId, address indexed owner, bytes32 dataHash, uint256 timestamp);
    event DataUpdated(uint256 indexed recordId, bytes32 newDataHash, uint256 timestamp);
    event DataDeleted(uint256 indexed recordId, address indexed owner);
    event OwnershipTransferred(uint256 indexed recordId, address indexed previousOwner, address indexed newOwner);
    
    modifier onlyRecordOwner(uint256 _recordId) {
        require(_recordId > 0 && _recordId <= recordCount, "Invalid record ID");
        require(records[_recordId].exists, "Record does not exist");
        require(records[_recordId].owner == msg.sender, "Not the record owner");
        _;
    }
    
    /**
     * @dev Store a new encrypted data hash
     * @param _dataHash The hash of the encrypted data
     * @param _description Optional description of the data
     */
    function storeData(bytes32 _dataHash, string memory _description) external returns (uint256) {
        require(_dataHash != bytes32(0), "Data hash cannot be empty");
        require(hashToRecordId[_dataHash] == 0, "Hash already exists");
        
        recordCount++;
        uint256 recordId = recordCount;
        
        records[recordId] = DataRecord({
            id: recordId,
            owner: msg.sender,
            dataHash: _dataHash,
            description: _description,
            timestamp: block.timestamp,
            exists: true
        });
        
        ownerRecords[msg.sender].push(recordId);
        hashToRecordId[_dataHash] = recordId;
        
        emit DataStored(recordId, msg.sender, _dataHash, block.timestamp);
        
        return recordId;
    }
    
    /**
     * @dev Store multiple data hashes in batch
     * @param _dataHashes Array of data hashes
     * @param _descriptions Array of descriptions
     */
    function batchStoreData(
        bytes32[] memory _dataHashes,
        string[] memory _descriptions
    ) external returns (uint256[] memory) {
        require(_dataHashes.length == _descriptions.length, "Arrays length mismatch");
        require(_dataHashes.length > 0, "Arrays cannot be empty");
        
        uint256[] memory recordIds = new uint256[](_dataHashes.length);
        
        for (uint256 i = 0; i < _dataHashes.length; i++) {
            require(_dataHashes[i] != bytes32(0), "Data hash cannot be empty");
            require(hashToRecordId[_dataHashes[i]] == 0, "Hash already exists");
            
            recordCount++;
            uint256 recordId = recordCount;
            
            records[recordId] = DataRecord({
                id: recordId,
                owner: msg.sender,
                dataHash: _dataHashes[i],
                description: _descriptions[i],
                timestamp: block.timestamp,
                exists: true
            });
            
            ownerRecords[msg.sender].push(recordId);
            hashToRecordId[_dataHashes[i]] = recordId;
            recordIds[i] = recordId;
            
            emit DataStored(recordId, msg.sender, _dataHashes[i], block.timestamp);
        }
        
        return recordIds;
    }
    
    /**
     * @dev Update an existing data hash
     * @param _recordId The record ID to update
     * @param _newDataHash The new data hash
     * @param _newDescription The new description
     */
    function updateData(
        uint256 _recordId,
        bytes32 _newDataHash,
        string memory _newDescription
    ) external onlyRecordOwner(_recordId) {
        require(_newDataHash != bytes32(0), "Data hash cannot be empty");
        require(hashToRecordId[_newDataHash] == 0 || hashToRecordId[_newDataHash] == _recordId, "Hash already exists");
        
        DataRecord storage record = records[_recordId];
        
        // Remove old hash mapping
        delete hashToRecordId[record.dataHash];
        
        // Update record
        record.dataHash = _newDataHash;
        record.description = _newDescription;
        record.timestamp = block.timestamp;
        
        // Add new hash mapping
        hashToRecordId[_newDataHash] = _recordId;
        
        emit DataUpdated(_recordId, _newDataHash, block.timestamp);
    }
    
    /**
     * @dev Delete a data record
     * @param _recordId The record ID to delete
     */
    function deleteData(uint256 _recordId) external onlyRecordOwner(_recordId) {
        DataRecord storage record = records[_recordId];
        
        // Remove hash mapping
        delete hashToRecordId[record.dataHash];
        
        // Mark as deleted
        record.exists = false;
        
        emit DataDeleted(_recordId, msg.sender);
    }
    
    /**
     * @dev Transfer ownership of a record to another address
     * @param _recordId The record ID to transfer
     * @param _newOwner The new owner address
     */
    function transferOwnership(uint256 _recordId, address _newOwner) external onlyRecordOwner(_recordId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        
        DataRecord storage record = records[_recordId];
        address previousOwner = record.owner;
        
        record.owner = _newOwner;
        ownerRecords[_newOwner].push(_recordId);
        
        emit OwnershipTransferred(_recordId, previousOwner, _newOwner);
    }
    
    /**
     * @dev Verify ownership of a data hash
     * @param _dataHash The data hash to verify
     * @param _claimedOwner The claimed owner address
     * @return True if the claimed owner owns the hash, false otherwise
     */
    function verifyOwnership(bytes32 _dataHash, address _claimedOwner) external view returns (bool) {
        uint256 recordId = hashToRecordId[_dataHash];
        
        if (recordId == 0 || !records[recordId].exists) {
            return false;
        }
        
        return records[recordId].owner == _claimedOwner;
    }
    
    /**
     * @dev Check if a data hash exists
     * @param _dataHash The data hash to check
     * @return True if exists, false otherwise
     */
    function dataHashExists(bytes32 _dataHash) external view returns (bool) {
        uint256 recordId = hashToRecordId[_dataHash];
        return recordId > 0 && records[recordId].exists;
    }
    
    /**
     * @dev Get record details
     * @param _recordId The record ID
     * @return id The record ID
     * @return owner The owner address
     * @return dataHash The data hash
     * @return description The description
     * @return timestamp The timestamp
     * @return exists Whether the record exists
     */
    function getRecord(uint256 _recordId) external view returns (
        uint256 id,
        address owner,
        bytes32 dataHash,
        string memory description,
        uint256 timestamp,
        bool exists
    ) {
        require(_recordId > 0 && _recordId <= recordCount, "Invalid record ID");
        
        DataRecord memory record = records[_recordId];
        
        return (
            record.id,
            record.owner,
            record.dataHash,
            record.description,
            record.timestamp,
            record.exists
        );
    }
    
    /**
     * @dev Get record by data hash
     * @param _dataHash The data hash
     * @return id The record ID
     * @return owner The owner address
     * @return dataHash The data hash
     * @return description The description
     * @return timestamp The timestamp
     * @return exists Whether the record exists
     */
    function getRecordByHash(bytes32 _dataHash) external view returns (
        uint256 id,
        address owner,
        bytes32 dataHash,
        string memory description,
        uint256 timestamp,
        bool exists
    ) {
        uint256 recordId = hashToRecordId[_dataHash];
        require(recordId > 0, "Record not found");
        
        DataRecord memory record = records[recordId];
        
        return (
            record.id,
            record.owner,
            record.dataHash,
            record.description,
            record.timestamp,
            record.exists
        );
    }
    
    /**
     * @dev Get all records owned by an address
     * @param _owner The owner address
     * @return Array of record IDs
     */
    function getRecordsByOwner(address _owner) external view returns (uint256[] memory) {
        return ownerRecords[_owner];
    }
    
    /**
     * @dev Get active records owned by an address
     * @param _owner The owner address
     * @return Array of active record IDs
     */
    function getActiveRecordsByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory allRecords = ownerRecords[_owner];
        uint256 activeCount = 0;
        
        // Count active records
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (records[allRecords[i]].exists) {
                activeCount++;
            }
        }
        
        uint256[] memory activeRecords = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (records[allRecords[i]].exists) {
                activeRecords[index] = allRecords[i];
                index++;
            }
        }
        
        return activeRecords;
    }
    
    /**
     * @dev Get the owner of a data hash
     * @param _dataHash The data hash
     * @return The owner address (address(0) if not found)
     */
    function getOwnerByHash(bytes32 _dataHash) external view returns (address) {
        uint256 recordId = hashToRecordId[_dataHash];
        
        if (recordId == 0 || !records[recordId].exists) {
            return address(0);
        }
        
        return records[recordId].owner;
    }
    
    /**
     * @dev Get the number of records owned by an address
     * @param _owner The owner address
     * @return The number of records
     */
    function getRecordCount(address _owner) external view returns (uint256) {
        return ownerRecords[_owner].length;
    }
    
    /**
     * @dev Get the number of active records owned by an address
     * @param _owner The owner address
     * @return The number of active records
     */
    function getActiveRecordCount(address _owner) external view returns (uint256) {
        uint256[] memory allRecords = ownerRecords[_owner];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (records[allRecords[i]].exists) {
                activeCount++;
            }
        }
        
        return activeCount;
    }
    
    /**
     * @dev Get total number of records created
     * @return The total record count
     */
    function getTotalRecords() external view returns (uint256) {
        return recordCount;
    }
}
