// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStore {
    struct Data {
        bytes32 hash;
        address owner;
    }

    mapping(uint256 => Data) public dataEntries;
    uint256 public nextId;

    event DataStored(uint256 id, address indexed owner, bytes32 hash);

    function storeData(bytes32 hash) external {
        dataEntries[nextId] = Data(hash, msg.sender);
        emit DataStored(nextId, msg.sender, hash);
        nextId++;
    }

    function verifyOwnership(uint256 id, address user) external view returns (bool) {
        return dataEntries[id].owner == user;
    }

    function getDataHash(uint256 id) external view returns (bytes32) {
        return dataEntries[id].hash;
    }
}
