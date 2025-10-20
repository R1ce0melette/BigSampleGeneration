// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStore {
    struct Data {
        address owner;
        bytes32 hash;
    }

    mapping(address => Data[]) public userDatas;

    event DataStored(address indexed user, uint256 index, bytes32 hash);

    function storeData(bytes32 hash) external {
        require(hash != bytes32(0), "Invalid hash");
        userDatas[msg.sender].push(Data({owner: msg.sender, hash: hash}));
        emit DataStored(msg.sender, userDatas[msg.sender].length - 1, hash);
    }

    function getData(address user, uint256 index) external view returns (bytes32, address) {
        require(index < userDatas[user].length, "Invalid index");
        Data storage d = userDatas[user][index];
        return (d.hash, d.owner);
    }

    function getDataCount(address user) external view returns (uint256) {
        return userDatas[user].length;
    }
}
