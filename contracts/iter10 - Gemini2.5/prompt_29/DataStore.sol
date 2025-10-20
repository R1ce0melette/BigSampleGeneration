// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataStore {
    struct DataRecord {
        bytes32 dataHash;
        address owner;
        uint256 timestamp;
    }

    mapping(bytes32 => DataRecord) public records;

    event DataStored(bytes32 indexed dataHash, address indexed owner);

    function storeData(bytes32 _dataHash) public {
        require(records[_dataHash].owner == address(0), "Data hash already exists.");
        
        records[_dataHash] = DataRecord({
            dataHash: _dataHash,
            owner: msg.sender,
            timestamp: block.timestamp
        });

        emit DataStored(_dataHash, msg.sender);
    }

    function verifyOwnership(bytes32 _dataHash) public view returns (address) {
        return records[_dataHash].owner;
    }

    function getTimestamp(bytes32 _dataHash) public view returns (uint256) {
        return records[_dataHash].timestamp;
    }
}
