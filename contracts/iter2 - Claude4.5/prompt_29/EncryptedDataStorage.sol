// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStorage {
    struct DataRecord {
        uint256 recordId;
        address owner;
        bytes32 dataHash;
        string description;
        uint256 timestamp;
        bool isActive;
    }
    
    uint256 public recordCount;
    mapping(uint256 => DataRecord) public records;
    mapping(address => uint256[]) public ownerRecords;
    mapping(bytes32 => uint256) public hashToRecordId;
    mapping(bytes32 => bool) public hashExists;
    
    event DataStored(uint256 indexed recordId, address indexed owner, bytes32 dataHash, uint256 timestamp);
    event DataUpdated(uint256 indexed recordId, bytes32 oldHash, bytes32 newHash, uint256 timestamp);
    event DataDeleted(uint256 indexed recordId, address indexed owner, uint256 timestamp);
    event OwnershipTransferred(uint256 indexed recordId, address indexed previousOwner, address indexed newOwner);
    
    modifier onlyRecordOwner(uint256 _recordId) {
        require(records[_recordId].owner == msg.sender, "Not the record owner");
        _;
    }
    
    modifier recordExists(uint256 _recordId) {
        require(_recordId > 0 && _recordId <= recordCount, "Invalid record ID");
        require(records[_recordId].isActive, "Record is not active");
        _;
    }
    
    function storeData(bytes32 _dataHash, string memory _description) external returns (uint256) {
        require(_dataHash != bytes32(0), "Data hash cannot be empty");
        require(!hashExists[_dataHash], "Data hash already exists");
        
        recordCount++;
        
        records[recordCount] = DataRecord({
            recordId: recordCount,
            owner: msg.sender,
            dataHash: _dataHash,
            description: _description,
            timestamp: block.timestamp,
            isActive: true
        });
        
        ownerRecords[msg.sender].push(recordCount);
        hashToRecordId[_dataHash] = recordCount;
        hashExists[_dataHash] = true;
        
        emit DataStored(recordCount, msg.sender, _dataHash, block.timestamp);
        
        return recordCount;
    }
    
    function updateData(uint256 _recordId, bytes32 _newDataHash, string memory _newDescription) external 
        recordExists(_recordId) 
        onlyRecordOwner(_recordId) 
    {
        require(_newDataHash != bytes32(0), "Data hash cannot be empty");
        require(!hashExists[_newDataHash], "New data hash already exists");
        
        DataRecord storage record = records[_recordId];
        bytes32 oldHash = record.dataHash;
        
        // Remove old hash mapping
        delete hashToRecordId[oldHash];
        delete hashExists[oldHash];
        
        // Update record
        record.dataHash = _newDataHash;
        record.description = _newDescription;
        record.timestamp = block.timestamp;
        
        // Add new hash mapping
        hashToRecordId[_newDataHash] = _recordId;
        hashExists[_newDataHash] = true;
        
        emit DataUpdated(_recordId, oldHash, _newDataHash, block.timestamp);
    }
    
    function deleteData(uint256 _recordId) external 
        recordExists(_recordId) 
        onlyRecordOwner(_recordId) 
    {
        DataRecord storage record = records[_recordId];
        
        // Remove hash mapping
        delete hashToRecordId[record.dataHash];
        delete hashExists[record.dataHash];
        
        // Mark as inactive
        record.isActive = false;
        
        emit DataDeleted(_recordId, msg.sender, block.timestamp);
    }
    
    function transferOwnership(uint256 _recordId, address _newOwner) external 
        recordExists(_recordId) 
        onlyRecordOwner(_recordId) 
    {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != msg.sender, "New owner is the same as current owner");
        
        DataRecord storage record = records[_recordId];
        address previousOwner = record.owner;
        
        record.owner = _newOwner;
        
        // Add to new owner's records
        ownerRecords[_newOwner].push(_recordId);
        
        emit OwnershipTransferred(_recordId, previousOwner, _newOwner);
    }
    
    function verifyOwnership(uint256 _recordId, address _claimedOwner) external view 
        recordExists(_recordId) 
        returns (bool) 
    {
        return records[_recordId].owner == _claimedOwner;
    }
    
    function verifyDataHash(uint256 _recordId, bytes32 _dataHash) external view 
        recordExists(_recordId) 
        returns (bool) 
    {
        return records[_recordId].dataHash == _dataHash;
    }
    
    function getRecord(uint256 _recordId) external view 
        recordExists(_recordId) 
        returns (
            address owner,
            bytes32 dataHash,
            string memory description,
            uint256 timestamp
        ) 
    {
        DataRecord memory record = records[_recordId];
        
        return (
            record.owner,
            record.dataHash,
            record.description,
            record.timestamp
        );
    }
    
    function getRecordByHash(bytes32 _dataHash) external view returns (
        uint256 recordId,
        address owner,
        string memory description,
        uint256 timestamp
    ) {
        require(hashExists[_dataHash], "Data hash does not exist");
        
        uint256 id = hashToRecordId[_dataHash];
        DataRecord memory record = records[id];
        
        return (
            record.recordId,
            record.owner,
            record.description,
            record.timestamp
        );
    }
    
    function getOwnerRecords(address _owner) external view returns (uint256[] memory) {
        return ownerRecords[_owner];
    }
    
    function getOwnerActiveRecords(address _owner) external view returns (uint256[] memory) {
        uint256[] memory allRecords = ownerRecords[_owner];
        uint256 activeCount = 0;
        
        // Count active records
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (records[allRecords[i]].isActive) {
                activeCount++;
            }
        }
        
        // Create array of active records
        uint256[] memory activeRecords = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (records[allRecords[i]].isActive) {
                activeRecords[index] = allRecords[i];
                index++;
            }
        }
        
        return activeRecords;
    }
    
    function isHashStored(bytes32 _dataHash) external view returns (bool) {
        return hashExists[_dataHash];
    }
    
    function getRecordIdByHash(bytes32 _dataHash) external view returns (uint256) {
        require(hashExists[_dataHash], "Data hash does not exist");
        return hashToRecordId[_dataHash];
    }
    
    function getTotalRecords() external view returns (uint256) {
        return recordCount;
    }
    
    function getActiveRecordCount() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= recordCount; i++) {
            if (records[i].isActive) {
                count++;
            }
        }
        
        return count;
    }
}
