// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EncryptedDataRegistry
 * @dev A contract for storing and verifying ownership of encrypted data hashes.
 */
contract EncryptedDataRegistry {

    struct DataEntry {
        bytes32 hash;
        address owner;
        uint256 timestamp;
    }

    mapping(bytes32 => DataEntry) public dataEntries;
    mapping(address => bytes32[]) public userHashes;

    event DataRegistered(bytes32 indexed dataHash, address indexed owner);

    /**
     * @dev Registers a new encrypted data hash.
     */
    function registerData(bytes32 _dataHash) public {
        require(dataEntries[_dataHash].owner == address(0), "Data hash is already registered.");

        dataEntries[_dataHash] = DataEntry({
            hash: _dataHash,
            owner: msg.sender,
            timestamp: block.timestamp
        });
        userHashes[msg.sender].push(_dataHash);

        emit DataRegistered(_dataHash, msg.sender);
    }

    /**
     * @dev Verifies the owner of a data hash.
     */
    function verifyOwner(bytes32 _dataHash) public view returns (address) {
        return dataEntries[_dataHash].owner;
    }

    /**
     * @dev Transfers ownership of a data hash to a new owner.
     */
    function transferOwnership(bytes32 _dataHash, address _newOwner) public {
        require(dataEntries[_dataHash].owner == msg.sender, "You are not the owner of this data.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        // Remove hash from old owner's list
        _removeHashFromUser(msg.sender, _dataHash);

        // Add hash to new owner's list and update entry
        dataEntries[_dataHash].owner = _newOwner;
        userHashes[_newOwner].push(_dataHash);
    }

    /**
     * @dev Helper function to remove a hash from a user's list.
     */
    function _removeHashFromUser(address _user, bytes32 _hash) private {
        bytes32[] storage hashes = userHashes[_user];
        for (uint i = 0; i < hashes.length; i++) {
            if (hashes[i] == _hash) {
                hashes[i] = hashes[hashes.length - 1];
                hashes.pop();
                break;
            }
        }
    }
}
