// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EncryptedDataStore {
    struct Data {
        address owner;
        bytes32 hash;
    }

    mapping(address => Data[]) public userDatas;

    event DataStored(address indexed user, bytes32 hash, uint256 index);

    function storeData(bytes32 hash) external {
        userDatas[msg.sender].push(Data({owner: msg.sender, hash: hash}));
        emit DataStored(msg.sender, hash, userDatas[msg.sender].length - 1);
    }

    function getData(address user, uint256 index) external view returns (address, bytes32) {
        require(index < userDatas[user].length, "Invalid index");
        Data storage d = userDatas[user][index];
        return (d.owner, d.hash);
    }

    function getDataCount(address user) external view returns (uint256) {
        return userDatas[user].length;
    }
}
