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
    event DataTransferred(bytes32 indexed dataHash, address indexed from, address indexed to);

    function storeData(bytes32 _dataHash) public {
        require(records[_dataHash].owner == address(0), "This data hash is already registered.");

        records[_dataHash] = DataRecord({
            dataHash: _dataHash,
            owner: msg.sender,
            timestamp: block.timestamp
        });

        emit DataStored(_dataHash, msg.sender);
    }

    function transferOwnership(bytes32 _dataHash, address _newOwner) public {
        require(records[_dataHash].owner == msg.sender, "Only the owner can transfer this data record.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address oldOwner = records[_dataHash].owner;
        records[_dataHash].owner = _newOwner;

        emit DataTransferred(_dataHash, oldOwner, _newOwner);
    }

    function verifyOwnership(bytes32 _dataHash, address _owner) public view returns (bool) {
        return records[_dataHash].owner == _owner;
    }

    function getRecord(bytes32 _dataHash) public view returns (address, uint256) {
        DataRecord storage record = records[_dataHash];
        return (record.owner, record.timestamp);
    }
}
