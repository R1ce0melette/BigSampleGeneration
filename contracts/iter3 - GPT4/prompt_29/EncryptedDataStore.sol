// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStore {
    struct Data {
        address owner;
        bytes32 hash;
    }

    mapping(uint256 => Data) public dataEntries;
    mapping(address => uint256[]) public userEntries;
    uint256 public nextId;

    event DataStored(address indexed owner, uint256 indexed id, bytes32 hash);

    function storeData(bytes32 hash) external {
        dataEntries[nextId] = Data(msg.sender, hash);
        userEntries[msg.sender].push(nextId);
        emit DataStored(msg.sender, nextId, hash);
        nextId++;
    }

    function verifyOwnership(uint256 id, address user) external view returns (bool) {
        return dataEntries[id].owner == user;
    }

    function getUserEntries(address user) external view returns (uint256[] memory) {
        return userEntries[user];
    }

    function getDataHash(uint256 id) external view returns (bytes32) {
        return dataEntries[id].hash;
    }
}
