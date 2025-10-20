// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EncryptedDataRegistry
 * @dev A contract that allows users to store and verify ownership of encrypted data hashes.
 */
contract EncryptedDataRegistry {
    // Struct to store information about a data hash.
    struct DataEntry {
        bytes32 hash;
        address owner;
        uint256 timestamp;
    }

    // Mapping from a data hash to its entry details.
    mapping(bytes32 => DataEntry) private dataEntries;

    // Mapping from an owner to a list of their registered data hashes.
    mapping(address => bytes32[]) private ownerHashes;

    /**
     * @dev Emitted when a new data hash is registered.
     * @param owner The address of the user who registered the hash.
     * @param hash The registered data hash.
     */
    event DataRegistered(address indexed owner, bytes32 indexed hash);

    /**
     * @dev Registers a new encrypted data hash, associating it with the caller's address.
     * @param _hash The hash of the encrypted data. Must be unique.
     */
    function registerHash(bytes32 _hash) public {
        require(dataEntries[_hash].owner == address(0), "This data hash is already registered.");
        
        dataEntries[_hash] = DataEntry({
            hash: _hash,
            owner: msg.sender,
            timestamp: block.timestamp
        });

        ownerHashes[msg.sender].push(_hash);

        emit DataRegistered(msg.sender, _hash);
    }

    /**
     * @dev Verifies the owner of a given data hash.
     * @param _hash The data hash to verify.
     * @return The address of the owner. Returns the zero address if the hash is not registered.
     */
    function verifyOwnership(bytes32 _hash) public view returns (address) {
        return dataEntries[_hash].owner;
    }

    /**
     * @dev Retrieves the details of a data entry.
     * @param _hash The data hash to query.
     * @return The owner, timestamp, and the hash itself.
     */
    function getEntry(bytes32 _hash) public view returns (address, uint256, bytes32) {
        DataEntry storage entry = dataEntries[_hash];
        require(entry.owner != address(0), "No entry found for this hash.");
        return (entry.owner, entry.timestamp, entry.hash);
    }

    /**
     * @dev Returns the list of data hashes registered by a specific owner.
     * @param _owner The address of the owner.
     * @return An array of data hashes.
     */
    function getHashesByOwner(address _owner) public view returns (bytes32[] memory) {
        return ownerHashes[_owner];
    }
}
