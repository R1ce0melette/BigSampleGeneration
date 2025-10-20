// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataRegistry {
    struct DataEntry {
        bytes32 dataHash;
        address owner;
        uint256 timestamp;
    }

    // Mapping from a data hash to its entry details
    mapping(bytes32 => DataEntry) public dataEntries;
    // An array to store all data hashes for iteration if needed (can be gas-intensive)
    bytes32[] public allDataHashes;

    event DataRegistered(bytes32 indexed dataHash, address indexed owner);
    event OwnershipTransferred(bytes32 indexed dataHash, address indexed from, address indexed to);

    /**
     * @dev Registers a new encrypted data hash to the sender's address.
     * @param _dataHash The keccak256 hash of the encrypted data.
     */
    function registerData(bytes32 _dataHash) public {
        require(dataEntries[_dataHash].owner == address(0), "Data hash is already registered.");
        
        dataEntries[_dataHash] = DataEntry({
            dataHash: _dataHash,
            owner: msg.sender,
            timestamp: block.timestamp
        });
        allDataHashes.push(_dataHash);

        emit DataRegistered(_dataHash, msg.sender);
    }

    /**
     * @dev Verifies if the sender is the owner of a given data hash.
     * @param _dataHash The data hash to verify.
     * @return True if the sender is the owner, false otherwise.
     */
    function isOwner(bytes32 _dataHash) public view returns (bool) {
        return dataEntries[_dataHash].owner == msg.sender;
    }

    /**
     * @dev Retrieves the owner of a specific data hash.
     * @param _dataHash The data hash.
     * @return The address of the owner.
     */
    function getOwner(bytes32 _dataHash) public view returns (address) {
        return dataEntries[_dataHash].owner;
    }

    /**
     * @dev Transfers the ownership of a data hash to a new owner.
     * @param _dataHash The data hash to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(bytes32 _dataHash, address _newOwner) public {
        require(dataEntries[_dataHash].owner == msg.sender, "Only the current owner can transfer ownership.");
        require(_newOwner != address(0), "New owner address cannot be zero.");
        require(dataEntries[_dataHash].owner != _newOwner, "New owner is the same as the old owner.");

        address oldOwner = dataEntries[_dataHash].owner;
        dataEntries[_dataHash].owner = _newOwner;

        emit OwnershipTransferred(_dataHash, oldOwner, _newOwner);
    }
}
