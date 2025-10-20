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
    event OwnershipTransferred(bytes32 indexed dataHash, address indexed from, address indexed to);

    function storeData(bytes32 _dataHash) public {
        require(records[_dataHash].owner == address(0), "This data hash is already registered.");
        
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

    function transferOwnership(bytes32 _dataHash, address _newOwner) public {
        require(records[_dataHash].owner == msg.sender, "Only the owner can transfer ownership.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address oldOwner = records[_dataHash].owner;
        records[_dataHash].owner = _newOwner;

        emit OwnershipTransferred(_dataHash, oldOwner, _newOwner);
    }
}
