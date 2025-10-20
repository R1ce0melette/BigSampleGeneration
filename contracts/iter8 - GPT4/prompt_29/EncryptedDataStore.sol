// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStore {
    struct Data {
        address owner;
        bytes32 hash;
    }

    mapping(bytes32 => Data) public dataRecords;

    event DataStored(address indexed owner, bytes32 indexed hash);

    function storeData(bytes32 hash) external {
        require(hash != bytes32(0), "Invalid hash");
        require(dataRecords[hash].owner == address(0), "Hash already stored");
        dataRecords[hash] = Data(msg.sender, hash);
        emit DataStored(msg.sender, hash);
    }

    function verifyOwnership(bytes32 hash, address user) external view returns (bool) {
        return dataRecords[hash].owner == user;
    }
}
