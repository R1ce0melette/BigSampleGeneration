// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EncryptedDataStore
 * @dev A contract that allows users to store and manage hashes of encrypted data.
 * Ownership of each data hash is tracked and verifiable.
 */
contract EncryptedDataStore {
    
    struct DataRecord {
        bytes32 dataHash;
        address owner;
        uint256 timestamp;
    }

    // Mapping from a data hash to its record
    mapping(bytes32 => DataRecord) public records;
    // Mapping from an owner to a list of their data hashes
    mapping(address => bytes32[]) public ownerHashes;

    event DataStored(address indexed owner, bytes32 indexed dataHash);
    event DataTransferred(bytes32 indexed dataHash, address indexed from, address indexed to);
    event DataDeleted(address indexed owner, bytes32 indexed dataHash);

    /**
     * @dev Stores a new data hash, assigning ownership to the sender.
     * @param _dataHash The hash of the encrypted data.
     */
    function storeData(bytes32 _dataHash) external {
        require(records[_dataHash].owner == address(0), "Data hash already exists.");
        
        records[_dataHash] = DataRecord({
            dataHash: _dataHash,
            owner: msg.sender,
            timestamp: block.timestamp
        });
        
        ownerHashes[msg.sender].push(_dataHash);
        
        emit DataStored(msg.sender, _dataHash);
    }

    /**
     * @dev Verifies the owner of a given data hash.
     * @param _dataHash The hash to check.
     * @return The address of the owner.
     */
    function getOwner(bytes32 _dataHash) external view returns (address) {
        return records[_dataHash].owner;
    }

    /**
     * @dev Transfers ownership of a data hash to a new owner.
     * @param _dataHash The hash to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferData(bytes32 _dataHash, address _newOwner) external {
        require(records[_dataHash].owner == msg.sender, "You are not the owner of this data.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");

        address oldOwner = msg.sender;

        // Remove hash from old owner's list
        bytes32[] storage hashes = ownerHashes[oldOwner];
        for (uint i = 0; i < hashes.length; i++) {
            if (hashes[i] == _dataHash) {
                hashes[i] = hashes[hashes.length - 1];
                hashes.pop();
                break;
            }
        }

        // Add hash to new owner's list and update record
        ownerHashes[_newOwner].push(_dataHash);
        records[_dataHash].owner = _newOwner;

        emit DataTransferred(_dataHash, oldOwner, _newOwner);
    }

    /**
     * @dev Deletes a data hash record. Only the owner can delete their data.
     * @param _dataHash The hash to delete.
     */
    function deleteData(bytes32 _dataHash) external {
        require(records[_dataHash].owner == msg.sender, "You are not the owner of this data.");

        // Remove hash from owner's list
        bytes32[] storage hashes = ownerHashes[msg.sender];
        for (uint i = 0; i < hashes.length; i++) {
            if (hashes[i] == _dataHash) {
                hashes[i] = hashes[hashes.length - 1];
                hashes.pop();
                break;
            }
        }

        // Delete the main record
        delete records[_dataHash];

        emit DataDeleted(msg.sender, _dataHash);
    }

    /**
     * @dev Retrieves all data hashes owned by the sender.
     * @return An array of data hashes.
     */
    function getMyHashes() external view returns (bytes32[] memory) {
        return ownerHashes[msg.sender];
    }
}
