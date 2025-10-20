// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStorage {
    struct DataRecord {
        uint256 id;
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
    event DataUpdated(uint256 indexed recordId, bytes32 newDataHash);
    event DataDeleted(uint256 indexed recordId);
    event OwnershipTransferred(uint256 indexed recordId, address indexed from, address indexed to);
    
    modifier onlyRecordOwner(uint256 _recordId) {
        require(_recordId > 0 && _recordId <= recordCount, "Record does not exist");
        require(records[_recordId].owner == msg.sender, "Not the record owner");
        _;
    }
    
    function storeData(bytes32 _dataHash, string memory _description) external {
        require(_dataHash != bytes32(0), "Invalid data hash");
        require(!hashExists[_dataHash], "Data hash already exists");
        
        recordCount++;
        
        records[recordCount] = DataRecord({
            id: recordCount,
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
    }
    
    function updateData(uint256 _recordId, bytes32 _newDataHash, string memory _newDescription) 
        external 
        onlyRecordOwner(_recordId) 
    {
        require(_newDataHash != bytes32(0), "Invalid data hash");
        require(records[_recordId].isActive, "Record is not active");
        
        DataRecord storage record = records[_recordId];
        
        // Remove old hash mapping
        delete hashExists[record.dataHash];
        delete hashToRecordId[record.dataHash];
        
        // Check new hash doesn't exist
        require(!hashExists[_newDataHash], "New data hash already exists");
        
        // Update record
        record.dataHash = _newDataHash;
        record.description = _newDescription;
        record.timestamp = block.timestamp;
        
        // Add new hash mapping
        hashToRecordId[_newDataHash] = _recordId;
        hashExists[_newDataHash] = true;
        
        emit DataUpdated(_recordId, _newDataHash);
    }
    
    function deleteData(uint256 _recordId) external onlyRecordOwner(_recordId) {
        require(records[_recordId].isActive, "Record is already deleted");
        
        DataRecord storage record = records[_recordId];
        
        // Remove hash mappings
        delete hashExists[record.dataHash];
        delete hashToRecordId[record.dataHash];
        
        record.isActive = false;
        
        emit DataDeleted(_recordId);
    }
    
    function transferOwnership(uint256 _recordId, address _newOwner) external onlyRecordOwner(_recordId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "New owner is the same as current owner");
        require(records[_recordId].isActive, "Record is not active");
        
        DataRecord storage record = records[_recordId];
        address previousOwner = record.owner;
        
        record.owner = _newOwner;
        ownerRecords[_newOwner].push(_recordId);
        
        emit OwnershipTransferred(_recordId, previousOwner, _newOwner);
    }
    
    function verifyOwnership(uint256 _recordId, address _owner) external view returns (bool) {
        require(_recordId > 0 && _recordId <= recordCount, "Record does not exist");
        return records[_recordId].owner == _owner && records[_recordId].isActive;
    }
    
    function verifyDataHash(bytes32 _dataHash) external view returns (bool exists, uint256 recordId, address owner) {
        if (!hashExists[_dataHash]) {
            return (false, 0, address(0));
        }
        
        recordId = hashToRecordId[_dataHash];
        DataRecord memory record = records[recordId];
        
        return (record.isActive, recordId, record.owner);
    }
    
    function getRecord(uint256 _recordId) external view returns (
        uint256 id,
        address owner,
        bytes32 dataHash,
        string memory description,
        uint256 timestamp,
        bool isActive
    ) {
        require(_recordId > 0 && _recordId <= recordCount, "Record does not exist");
        
        DataRecord memory record = records[_recordId];
        
        return (
            record.id,
            record.owner,
            record.dataHash,
            record.description,
            record.timestamp,
            record.isActive
        );
    }
    
    function getOwnerRecords(address _owner) external view returns (uint256[] memory) {
        return ownerRecords[_owner];
    }
    
    function getMyRecords() external view returns (uint256[] memory) {
        return ownerRecords[msg.sender];
    }
    
    function getActiveRecords(address _owner) external view returns (uint256[] memory) {
        uint256[] memory allRecords = ownerRecords[_owner];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allRecords.length; i++) {
            if (records[allRecords[i]].isActive) {
                activeCount++;
            }
        }
        
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
    
    function getRecordByHash(bytes32 _dataHash) external view returns (
        uint256 id,
        address owner,
        string memory description,
        uint256 timestamp,
        bool isActive
    ) {
        require(hashExists[_dataHash], "Data hash does not exist");
        
        uint256 recordId = hashToRecordId[_dataHash];
        DataRecord memory record = records[recordId];
        
        return (
            record.id,
            record.owner,
            record.description,
            record.timestamp,
            record.isActive
        );
    }
    
    function getTotalRecords() external view returns (uint256) {
        return recordCount;
    }
    
    function getOwnerRecordCount(address _owner) external view returns (uint256) {
        return ownerRecords[_owner].length;
    }
}
