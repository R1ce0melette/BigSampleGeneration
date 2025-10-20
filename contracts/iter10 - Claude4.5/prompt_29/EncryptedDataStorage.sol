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
    mapping(bytes32 => bool) public hashExists;
    mapping(bytes32 => uint256) public hashToRecordId;

    event DataStored(uint256 indexed recordId, address indexed owner, bytes32 dataHash, uint256 timestamp);
    event DataUpdated(uint256 indexed recordId, bytes32 oldHash, bytes32 newHash, uint256 timestamp);
    event DataDeleted(uint256 indexed recordId, address indexed owner);
    event OwnershipTransferred(uint256 indexed recordId, address indexed from, address indexed to);

    modifier onlyRecordOwner(uint256 recordId) {
        require(recordId > 0 && recordId <= recordCount, "Record does not exist");
        require(records[recordId].exists, "Record does not exist");
        require(records[recordId].owner == msg.sender, "Not the record owner");
        _;
    }

    modifier recordExists(uint256 recordId) {
        require(recordId > 0 && recordId <= recordCount, "Record does not exist");
        require(records[recordId].exists, "Record does not exist");
        _;
    }

    function storeData(bytes32 dataHash, string memory description) external returns (uint256) {
        require(dataHash != bytes32(0), "Invalid data hash");
        require(!hashExists[dataHash], "Data hash already exists");
        require(bytes(description).length > 0, "Description cannot be empty");

        recordCount++;
        uint256 newRecordId = recordCount;

        records[newRecordId] = DataRecord({
            id: newRecordId,
            owner: msg.sender,
            dataHash: dataHash,
            description: description,
            timestamp: block.timestamp,
            exists: true
        });

        ownerRecords[msg.sender].push(newRecordId);
        hashExists[dataHash] = true;
        hashToRecordId[dataHash] = newRecordId;

        emit DataStored(newRecordId, msg.sender, dataHash, block.timestamp);

        return newRecordId;
    }

    function updateDataHash(uint256 recordId, bytes32 newDataHash) external onlyRecordOwner(recordId) {
        require(newDataHash != bytes32(0), "Invalid data hash");
        require(!hashExists[newDataHash], "New data hash already exists");

        DataRecord storage record = records[recordId];
        bytes32 oldHash = record.dataHash;

        // Remove old hash mapping
        delete hashExists[oldHash];
        delete hashToRecordId[oldHash];

        // Update to new hash
        record.dataHash = newDataHash;
        record.timestamp = block.timestamp;

        hashExists[newDataHash] = true;
        hashToRecordId[newDataHash] = recordId;

        emit DataUpdated(recordId, oldHash, newDataHash, block.timestamp);
    }

    function updateDescription(uint256 recordId, string memory newDescription) external onlyRecordOwner(recordId) {
        require(bytes(newDescription).length > 0, "Description cannot be empty");

        records[recordId].description = newDescription;
        records[recordId].timestamp = block.timestamp;
    }

    function deleteRecord(uint256 recordId) external onlyRecordOwner(recordId) {
        DataRecord storage record = records[recordId];
        
        // Remove hash mappings
        delete hashExists[record.dataHash];
        delete hashToRecordId[record.dataHash];

        // Remove from owner's records
        _removeRecordFromOwner(msg.sender, recordId);

        // Mark as deleted
        record.exists = false;

        emit DataDeleted(recordId, msg.sender);
    }

    function transferOwnership(uint256 recordId, address newOwner) external onlyRecordOwner(recordId) {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != msg.sender, "New owner is the same as current owner");

        DataRecord storage record = records[recordId];
        address previousOwner = record.owner;

        // Remove from previous owner's records
        _removeRecordFromOwner(previousOwner, recordId);

        // Add to new owner's records
        ownerRecords[newOwner].push(recordId);

        // Update ownership
        record.owner = newOwner;

        emit OwnershipTransferred(recordId, previousOwner, newOwner);
    }

    function _removeRecordFromOwner(address owner, uint256 recordId) private {
        uint256[] storage records = ownerRecords[owner];
        
        for (uint256 i = 0; i < records.length; i++) {
            if (records[i] == recordId) {
                records[i] = records[records.length - 1];
                records.pop();
                break;
            }
        }
    }

    function verifyOwnership(uint256 recordId, address claimedOwner) external view recordExists(recordId) returns (bool) {
        return records[recordId].owner == claimedOwner;
    }

    function verifyDataHash(bytes32 dataHash) external view returns (bool exists, uint256 recordId, address owner) {
        if (!hashExists[dataHash]) {
            return (false, 0, address(0));
        }
        
        uint256 id = hashToRecordId[dataHash];
        DataRecord memory record = records[id];
        
        return (true, id, record.owner);
    }

    function getRecord(uint256 recordId) external view recordExists(recordId) returns (
        uint256 id,
        address owner,
        bytes32 dataHash,
        string memory description,
        uint256 timestamp
    ) {
        DataRecord memory record = records[recordId];
        return (record.id, record.owner, record.dataHash, record.description, record.timestamp);
    }

    function getOwnerRecords(address owner) external view returns (uint256[] memory) {
        return ownerRecords[owner];
    }

    function getOwnerRecordCount(address owner) external view returns (uint256) {
        return ownerRecords[owner].length;
    }

    function getRecordsByOwner(address owner) external view returns (DataRecord[] memory) {
        uint256[] memory recordIds = ownerRecords[owner];
        DataRecord[] memory ownerRecordsData = new DataRecord[](recordIds.length);

        for (uint256 i = 0; i < recordIds.length; i++) {
            ownerRecordsData[i] = records[recordIds[i]];
        }

        return ownerRecordsData;
    }

    function isHashUnique(bytes32 dataHash) external view returns (bool) {
        return !hashExists[dataHash];
    }

    function getRecordIdByHash(bytes32 dataHash) external view returns (uint256) {
        require(hashExists[dataHash], "Hash does not exist");
        return hashToRecordId[dataHash];
    }
}
