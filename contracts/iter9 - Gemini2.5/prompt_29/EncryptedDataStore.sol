// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStore {
    struct DataRecord {
        bytes32 dataHash;
        address owner;
        uint256 timestamp;
    }

    mapping(bytes32 => DataRecord) public dataRecords;

    event DataStored(bytes32 indexed dataHash, address indexed owner);

    function storeData(bytes32 _dataHash) public {
        require(dataRecords[_dataHash].owner == address(0), "Data hash already exists.");
        
        dataRecords[_dataHash] = DataRecord({
            dataHash: _dataHash,
            owner: msg.sender,
            timestamp: block.timestamp
        });

        emit DataStored(_dataHash, msg.sender);
    }

    function verifyOwnership(bytes32 _dataHash, address _owner) public view returns (bool) {
        return dataRecords[_dataHash].owner == _owner;
    }

    function getDataTimestamp(bytes32 _dataHash) public view returns (uint256) {
        require(dataRecords[_dataHash].owner != address(0), "Data hash not found.");
        return dataRecords[_dataHash].timestamp;
    }
}
