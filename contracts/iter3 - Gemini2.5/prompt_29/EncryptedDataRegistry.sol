// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EncryptedDataRegistry
 * @dev A contract that allows users to store hashes of encrypted data on-chain
 * and verify ownership of these hashes.
 */
contract EncryptedDataRegistry {
    struct DataRecord {
        bytes32 dataHash;
        address owner;
        uint256 timestamp;
    }

    // Mapping from a data hash to its record details
    mapping(bytes32 => DataRecord) public records;
    // Mapping from an owner address to a list of their data hashes
    mapping(address => bytes32[]) public ownerHashes;

    /**
     * @dev Emitted when a new data hash is registered.
     * @param owner The address of the user registering the hash.
     * @param dataHash The hash of the encrypted data.
     */
    event DataRegistered(address indexed owner, bytes32 indexed dataHash);

    /**
     * @dev Emitted when the ownership of a data hash is transferred.
     * @param dataHash The hash being transferred.
     * @param from The previous owner.
     * @param to The new owner.
     */
    event OwnershipTransferred(bytes32 indexed dataHash, address indexed from, address indexed to);

    /**
     * @dev Registers a new data hash, associating it with the sender's address.
     * The hash must not have been previously registered.
     * @param _dataHash The hash of the encrypted data to be stored.
     */
    function registerData(bytes32 _dataHash) public {
        require(_dataHash != bytes32(0), "Data hash cannot be zero.");
        require(records[_dataHash].owner == address(0), "This data hash is already registered.");

        records[_dataHash] = DataRecord({
            dataHash: _dataHash,
            owner: msg.sender,
            timestamp: block.timestamp
        });

        ownerHashes[msg.sender].push(_dataHash);

        emit DataRegistered(msg.sender, _dataHash);
    }

    /**
     * @dev Verifies the owner of a given data hash.
     * @param _dataHash The data hash to verify.
     * @return The address of the owner. Returns the zero address if not registered.
     */
    function verifyOwnership(bytes32 _dataHash) public view returns (address) {
        return records[_dataHash].owner;
    }

    /**
     * @dev Transfers the ownership of a registered data hash to a new owner.
     * Only the current owner of the hash can initiate the transfer.
     * @param _dataHash The data hash to be transferred.
     * @param _newOwner The address of the new owner.
     */
    function transferDataOwnership(bytes32 _dataHash, address _newOwner) public {
        require(records[_dataHash].owner == msg.sender, "Only the owner can transfer this data record.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        require(_newOwner != msg.sender, "New owner is the same as the current owner.");

        address oldOwner = msg.sender;
        records[_dataHash].owner = _newOwner;
        ownerHashes[_newOwner].push(_dataHash);

        // Remove the hash from the old owner's list
        bytes32[] storage hashes = ownerHashes[oldOwner];
        for (uint i = 0; i < hashes.length; i++) {
            if (hashes[i] == _dataHash) {
                hashes[i] = hashes[hashes.length - 1];
                hashes.pop();
                break;
            }
        }

        emit OwnershipTransferred(_dataHash, oldOwner, _newOwner);
    }

    /**
     * @dev Retrieves all data hashes registered by a specific owner.
     * @param _owner The address of the owner.
     * @return An array of data hashes.
     */
    function getHashesByOwner(address _owner) public view returns (bytes32[] memory) {
        return ownerHashes[_owner];
    }

    /**
     * @dev Retrieves the details of a specific data record.
     * @param _dataHash The hash of the data record.
     * @return A tuple containing the hash, owner, and timestamp.
     */
    function getRecord(bytes32 _dataHash) public view returns (bytes32, address, uint256) {
        DataRecord storage record = records[_dataHash];
        return (record.dataHash, record.owner, record.timestamp);
    }
}
