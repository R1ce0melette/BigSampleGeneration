// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EncryptedDataStorage
 * @dev A contract that lets users store encrypted data hashes on-chain with ownership verification
 */
contract EncryptedDataStorage {
    struct DataRecord {
        uint256 recordId;
        address owner;
        bytes32 dataHash;
        string encryptedData;
        uint256 timestamp;
        string description;
        bool isActive;
    }
    
    uint256 public totalRecords;
    address public owner;
    
    mapping(uint256 => DataRecord) public records;
    mapping(address => uint256[]) public userRecords;
    mapping(bytes32 => bool) public hashExists;
    mapping(bytes32 => uint256) public hashToRecordId;
    
    // Events
    event DataStored(uint256 indexed recordId, address indexed owner, bytes32 dataHash, uint256 timestamp);
    event DataUpdated(uint256 indexed recordId, bytes32 newDataHash, uint256 timestamp);
    event DataDeleted(uint256 indexed recordId, address indexed owner, uint256 timestamp);
    event OwnershipTransferred(uint256 indexed recordId, address indexed previousOwner, address indexed newOwner);
    
    modifier onlyContractOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier onlyRecordOwner(uint256 _recordId) {
        require(records[_recordId].recordId != 0, "Record does not exist");
        require(records[_recordId].owner == msg.sender, "Only record owner can call this function");
        require(records[_recordId].isActive, "Record is not active");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Stores encrypted data hash on-chain
     * @param _dataHash The hash of the data
     * @param _encryptedData The encrypted data (could be IPFS hash or encrypted content)
     * @param _description Description of the data
     */
    function storeData(
        bytes32 _dataHash,
        string memory _encryptedData,
        string memory _description
    ) external returns (uint256) {
        require(_dataHash != bytes32(0), "Invalid data hash");
        require(!hashExists[_dataHash], "Data hash already exists");
        require(bytes(_encryptedData).length > 0, "Encrypted data cannot be empty");
        
        totalRecords++;
        uint256 recordId = totalRecords;
        
        records[recordId] = DataRecord({
            recordId: recordId,
            owner: msg.sender,
            dataHash: _dataHash,
            encryptedData: _encryptedData,
            timestamp: block.timestamp,
            description: _description,
            isActive: true
        });
        
        hashExists[_dataHash] = true;
        hashToRecordId[_dataHash] = recordId;
        userRecords[msg.sender].push(recordId);
        
        emit DataStored(recordId, msg.sender, _dataHash, block.timestamp);
        
        return recordId;
    }
    
    /**
     * @dev Updates the encrypted data for a record
     * @param _recordId The ID of the record to update
     * @param _newDataHash The new data hash
     * @param _newEncryptedData The new encrypted data
     * @param _newDescription The new description
     */
    function updateData(
        uint256 _recordId,
        bytes32 _newDataHash,
        string memory _newEncryptedData,
        string memory _newDescription
    ) external onlyRecordOwner(_recordId) {
        require(_newDataHash != bytes32(0), "Invalid data hash");
        require(bytes(_newEncryptedData).length > 0, "Encrypted data cannot be empty");
        
        // Remove old hash from existence check
        bytes32 oldHash = records[_recordId].dataHash;
        if (oldHash != _newDataHash) {
            hashExists[oldHash] = false;
            delete hashToRecordId[oldHash];
            
            require(!hashExists[_newDataHash], "New data hash already exists");
            hashExists[_newDataHash] = true;
            hashToRecordId[_newDataHash] = _recordId;
        }
        
        records[_recordId].dataHash = _newDataHash;
        records[_recordId].encryptedData = _newEncryptedData;
        records[_recordId].description = _newDescription;
        records[_recordId].timestamp = block.timestamp;
        
        emit DataUpdated(_recordId, _newDataHash, block.timestamp);
    }
    
    /**
     * @dev Deletes (deactivates) a data record
     * @param _recordId The ID of the record to delete
     */
    function deleteData(uint256 _recordId) external onlyRecordOwner(_recordId) {
        records[_recordId].isActive = false;
        
        bytes32 dataHash = records[_recordId].dataHash;
        hashExists[dataHash] = false;
        delete hashToRecordId[dataHash];
        
        emit DataDeleted(_recordId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Transfers ownership of a data record
     * @param _recordId The ID of the record
     * @param _newOwner The address of the new owner
     */
    function transferRecordOwnership(uint256 _recordId, address _newOwner) external onlyRecordOwner(_recordId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "New owner must be different");
        
        address previousOwner = records[_recordId].owner;
        records[_recordId].owner = _newOwner;
        
        userRecords[_newOwner].push(_recordId);
        
        emit OwnershipTransferred(_recordId, previousOwner, _newOwner);
    }
    
    /**
     * @dev Retrieves a data record by ID
     * @param _recordId The ID of the record
     * @return recordId The record ID
     * @return recordOwner The owner's address
     * @return dataHash The data hash
     * @return encryptedData The encrypted data
     * @return timestamp When the record was created/updated
     * @return description The description
     * @return isActive Whether the record is active
     */
    function getRecord(uint256 _recordId) external view returns (
        uint256 recordId,
        address recordOwner,
        bytes32 dataHash,
        string memory encryptedData,
        uint256 timestamp,
        string memory description,
        bool isActive
    ) {
        require(records[_recordId].recordId != 0, "Record does not exist");
        
        DataRecord memory record = records[_recordId];
        
        return (
            record.recordId,
            record.owner,
            record.dataHash,
            record.encryptedData,
            record.timestamp,
            record.description,
            record.isActive
        );
    }
    
    /**
     * @dev Retrieves the encrypted data for a record (only owner can access)
     * @param _recordId The ID of the record
     * @return The encrypted data
     */
    function getEncryptedData(uint256 _recordId) external view onlyRecordOwner(_recordId) returns (string memory) {
        return records[_recordId].encryptedData;
    }
    
    /**
     * @dev Retrieves the data hash for a record
     * @param _recordId The ID of the record
     * @return The data hash
     */
    function getDataHash(uint256 _recordId) external view returns (bytes32) {
        require(records[_recordId].recordId != 0, "Record does not exist");
        return records[_recordId].dataHash;
    }
    
    /**
     * @dev Retrieves all record IDs for a user
     * @param _user The address of the user
     * @return Array of record IDs
     */
    function getUserRecords(address _user) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count active records owned by user
        for (uint256 i = 0; i < userRecords[_user].length; i++) {
            uint256 recordId = userRecords[_user][i];
            if (records[recordId].owner == _user && records[recordId].isActive) {
                count++;
            }
        }
        
        // Create array of active record IDs
        uint256[] memory activeRecords = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userRecords[_user].length; i++) {
            uint256 recordId = userRecords[_user][i];
            if (records[recordId].owner == _user && records[recordId].isActive) {
                activeRecords[index] = recordId;
                index++;
            }
        }
        
        return activeRecords;
    }
    
    /**
     * @dev Retrieves all record IDs for the caller
     * @return Array of record IDs
     */
    function getMyRecords() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < userRecords[msg.sender].length; i++) {
            uint256 recordId = userRecords[msg.sender][i];
            if (records[recordId].owner == msg.sender && records[recordId].isActive) {
                count++;
            }
        }
        
        uint256[] memory myRecords = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userRecords[msg.sender].length; i++) {
            uint256 recordId = userRecords[msg.sender][i];
            if (records[recordId].owner == msg.sender && records[recordId].isActive) {
                myRecords[index] = recordId;
                index++;
            }
        }
        
        return myRecords;
    }
    
    /**
     * @dev Verifies ownership of a record
     * @param _recordId The ID of the record
     * @param _user The address to verify
     * @return True if the user owns the record, false otherwise
     */
    function verifyOwnership(uint256 _recordId, address _user) external view returns (bool) {
        if (records[_recordId].recordId == 0) {
            return false;
        }
        
        return records[_recordId].owner == _user && records[_recordId].isActive;
    }
    
    /**
     * @dev Verifies if a data hash exists
     * @param _dataHash The hash to verify
     * @return True if exists, false otherwise
     */
    function verifyDataHash(bytes32 _dataHash) external view returns (bool) {
        return hashExists[_dataHash];
    }
    
    /**
     * @dev Gets the record ID associated with a data hash
     * @param _dataHash The data hash
     * @return The record ID (0 if not found)
     */
    function getRecordIdByHash(bytes32 _dataHash) external view returns (uint256) {
        return hashToRecordId[_dataHash];
    }
    
    /**
     * @dev Checks if a record exists and is active
     * @param _recordId The ID of the record
     * @return True if exists and is active, false otherwise
     */
    function isRecordActive(uint256 _recordId) external view returns (bool) {
        if (records[_recordId].recordId == 0) {
            return false;
        }
        
        return records[_recordId].isActive;
    }
    
    /**
     * @dev Returns the total number of records created
     * @return Total number of records
     */
    function getTotalRecords() external view returns (uint256) {
        return totalRecords;
    }
    
    /**
     * @dev Returns the total number of active records
     * @return Count of active records
     */
    function getActiveRecordsCount() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalRecords; i++) {
            if (records[i].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Returns the number of records owned by a user
     * @param _user The address of the user
     * @return Count of active records
     */
    function getUserRecordsCount(address _user) external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < userRecords[_user].length; i++) {
            uint256 recordId = userRecords[_user][i];
            if (records[recordId].owner == _user && records[recordId].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Batch stores multiple data records
     * @param _dataHashes Array of data hashes
     * @param _encryptedDataArray Array of encrypted data
     * @param _descriptions Array of descriptions
     * @return Array of record IDs created
     */
    function batchStoreData(
        bytes32[] memory _dataHashes,
        string[] memory _encryptedDataArray,
        string[] memory _descriptions
    ) external returns (uint256[] memory) {
        require(_dataHashes.length > 0, "Arrays cannot be empty");
        require(_dataHashes.length == _encryptedDataArray.length, "Arrays length mismatch");
        require(_dataHashes.length == _descriptions.length, "Arrays length mismatch");
        
        uint256[] memory recordIds = new uint256[](_dataHashes.length);
        
        for (uint256 i = 0; i < _dataHashes.length; i++) {
            require(_dataHashes[i] != bytes32(0), "Invalid data hash");
            require(!hashExists[_dataHashes[i]], "Data hash already exists");
            require(bytes(_encryptedDataArray[i]).length > 0, "Encrypted data cannot be empty");
            
            totalRecords++;
            uint256 recordId = totalRecords;
            
            records[recordId] = DataRecord({
                recordId: recordId,
                owner: msg.sender,
                dataHash: _dataHashes[i],
                encryptedData: _encryptedDataArray[i],
                timestamp: block.timestamp,
                description: _descriptions[i],
                isActive: true
            });
            
            hashExists[_dataHashes[i]] = true;
            hashToRecordId[_dataHashes[i]] = recordId;
            userRecords[msg.sender].push(recordId);
            
            recordIds[i] = recordId;
            
            emit DataStored(recordId, msg.sender, _dataHashes[i], block.timestamp);
        }
        
        return recordIds;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferContractOwnership(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
