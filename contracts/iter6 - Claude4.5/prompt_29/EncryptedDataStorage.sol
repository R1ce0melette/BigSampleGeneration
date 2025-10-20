// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EncryptedDataStorage
 * @dev A contract that lets users store encrypted data hashes on-chain with ownership verification
 */
contract EncryptedDataStorage {
    struct DataRecord {
        bytes32 dataHash;
        address owner;
        uint256 timestamp;
        string description;
        bool exists;
        bool isPublic;
    }
    
    address public contractOwner;
    
    mapping(bytes32 => DataRecord) public dataRecords;
    mapping(address => bytes32[]) public userDataHashes;
    mapping(bytes32 => mapping(address => bool)) public sharedWith;
    
    bytes32[] public allDataHashes;
    
    // Events
    event DataStored(bytes32 indexed dataHash, address indexed owner, uint256 timestamp, bool isPublic);
    event DataUpdated(bytes32 indexed dataHash, address indexed owner, uint256 timestamp);
    event DataDeleted(bytes32 indexed dataHash, address indexed owner, uint256 timestamp);
    event DataShared(bytes32 indexed dataHash, address indexed owner, address indexed sharedWith);
    event DataUnshared(bytes32 indexed dataHash, address indexed owner, address indexed unsharedWith);
    event OwnershipTransferred(bytes32 indexed dataHash, address indexed previousOwner, address indexed newOwner);
    event VisibilityChanged(bytes32 indexed dataHash, bool isPublic);
    
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only contract owner can perform this action");
        _;
    }
    
    modifier onlyDataOwner(bytes32 dataHash) {
        require(dataRecords[dataHash].exists, "Data record does not exist");
        require(dataRecords[dataHash].owner == msg.sender, "Only data owner can perform this action");
        _;
    }
    
    modifier dataExists(bytes32 dataHash) {
        require(dataRecords[dataHash].exists, "Data record does not exist");
        _;
    }
    
    constructor() {
        contractOwner = msg.sender;
    }
    
    /**
     * @dev Store encrypted data hash
     * @param dataHash The hash of the encrypted data
     * @param description Description of the data
     * @param isPublic Whether the data is publicly accessible
     */
    function storeData(bytes32 dataHash, string memory description, bool isPublic) external {
        require(dataHash != bytes32(0), "Invalid data hash");
        require(!dataRecords[dataHash].exists, "Data hash already exists");
        
        dataRecords[dataHash] = DataRecord({
            dataHash: dataHash,
            owner: msg.sender,
            timestamp: block.timestamp,
            description: description,
            exists: true,
            isPublic: isPublic
        });
        
        userDataHashes[msg.sender].push(dataHash);
        allDataHashes.push(dataHash);
        
        emit DataStored(dataHash, msg.sender, block.timestamp, isPublic);
    }
    
    /**
     * @dev Update data record metadata
     * @param dataHash The hash of the data
     * @param description New description
     */
    function updateData(bytes32 dataHash, string memory description) external onlyDataOwner(dataHash) {
        dataRecords[dataHash].description = description;
        dataRecords[dataHash].timestamp = block.timestamp;
        
        emit DataUpdated(dataHash, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Delete a data record
     * @param dataHash The hash of the data to delete
     */
    function deleteData(bytes32 dataHash) external onlyDataOwner(dataHash) {
        delete dataRecords[dataHash];
        
        emit DataDeleted(dataHash, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Change visibility of data
     * @param dataHash The hash of the data
     * @param isPublic New visibility status
     */
    function setVisibility(bytes32 dataHash, bool isPublic) external onlyDataOwner(dataHash) {
        dataRecords[dataHash].isPublic = isPublic;
        
        emit VisibilityChanged(dataHash, isPublic);
    }
    
    /**
     * @dev Share data with another address
     * @param dataHash The hash of the data to share
     * @param user The address to share with
     */
    function shareData(bytes32 dataHash, address user) external onlyDataOwner(dataHash) {
        require(user != address(0), "Invalid user address");
        require(user != msg.sender, "Cannot share with yourself");
        require(!sharedWith[dataHash][user], "Already shared with this user");
        
        sharedWith[dataHash][user] = true;
        
        emit DataShared(dataHash, msg.sender, user);
    }
    
    /**
     * @dev Revoke data sharing
     * @param dataHash The hash of the data
     * @param user The address to revoke access from
     */
    function unshareData(bytes32 dataHash, address user) external onlyDataOwner(dataHash) {
        require(sharedWith[dataHash][user], "Not shared with this user");
        
        sharedWith[dataHash][user] = false;
        
        emit DataUnshared(dataHash, msg.sender, user);
    }
    
    /**
     * @dev Transfer ownership of data
     * @param dataHash The hash of the data
     * @param newOwner The new owner address
     */
    function transferOwnership(bytes32 dataHash, address newOwner) external onlyDataOwner(dataHash) {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != msg.sender, "Already the owner");
        
        address previousOwner = msg.sender;
        dataRecords[dataHash].owner = newOwner;
        
        // Add to new owner's list
        userDataHashes[newOwner].push(dataHash);
        
        emit OwnershipTransferred(dataHash, previousOwner, newOwner);
    }
    
    /**
     * @dev Get data record details
     * @param dataHash The hash of the data
     * @return owner Owner address
     * @return timestamp Creation timestamp
     * @return description Description
     * @return isPublic Visibility status
     */
    function getData(bytes32 dataHash) external view dataExists(dataHash) returns (
        address owner,
        uint256 timestamp,
        string memory description,
        bool isPublic
    ) {
        DataRecord memory record = dataRecords[dataHash];
        
        // Check access permissions
        require(
            record.owner == msg.sender || 
            record.isPublic || 
            sharedWith[dataHash][msg.sender] ||
            msg.sender == contractOwner,
            "No permission to access this data"
        );
        
        return (
            record.owner,
            record.timestamp,
            record.description,
            record.isPublic
        );
    }
    
    /**
     * @dev Verify ownership of data
     * @param dataHash The hash of the data
     * @param user The address to verify
     * @return True if user is owner
     */
    function verifyOwnership(bytes32 dataHash, address user) external view dataExists(dataHash) returns (bool) {
        return dataRecords[dataHash].owner == user;
    }
    
    /**
     * @dev Check if data exists
     * @param dataHash The hash of the data
     * @return True if exists
     */
    function exists(bytes32 dataHash) external view returns (bool) {
        return dataRecords[dataHash].exists;
    }
    
    /**
     * @dev Check if user has access to data
     * @param dataHash The hash of the data
     * @param user The address to check
     * @return True if user has access
     */
    function hasAccess(bytes32 dataHash, address user) external view dataExists(dataHash) returns (bool) {
        DataRecord memory record = dataRecords[dataHash];
        return record.owner == user || record.isPublic || sharedWith[dataHash][user];
    }
    
    /**
     * @dev Get all data hashes owned by a user
     * @param user The owner address
     * @return Array of data hashes
     */
    function getUserDataHashes(address user) external view returns (bytes32[] memory) {
        return userDataHashes[user];
    }
    
    /**
     * @dev Get all data hashes owned by caller
     * @return Array of data hashes
     */
    function getMyDataHashes() external view returns (bytes32[] memory) {
        return userDataHashes[msg.sender];
    }
    
    /**
     * @dev Get data hashes shared with a user
     * @param user The user address
     * @return Array of data hashes
     */
    function getSharedDataHashes(address user) external view returns (bytes32[] memory) {
        uint256 count = 0;
        
        // Count shared data
        for (uint256 i = 0; i < allDataHashes.length; i++) {
            if (dataRecords[allDataHashes[i]].exists && sharedWith[allDataHashes[i]][user]) {
                count++;
            }
        }
        
        // Collect shared data hashes
        bytes32[] memory sharedHashes = new bytes32[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allDataHashes.length; i++) {
            if (dataRecords[allDataHashes[i]].exists && sharedWith[allDataHashes[i]][user]) {
                sharedHashes[index] = allDataHashes[i];
                index++;
            }
        }
        
        return sharedHashes;
    }
    
    /**
     * @dev Get all public data hashes
     * @return Array of public data hashes
     */
    function getPublicDataHashes() external view returns (bytes32[] memory) {
        uint256 count = 0;
        
        // Count public data
        for (uint256 i = 0; i < allDataHashes.length; i++) {
            if (dataRecords[allDataHashes[i]].exists && dataRecords[allDataHashes[i]].isPublic) {
                count++;
            }
        }
        
        // Collect public data hashes
        bytes32[] memory publicHashes = new bytes32[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allDataHashes.length; i++) {
            if (dataRecords[allDataHashes[i]].exists && dataRecords[allDataHashes[i]].isPublic) {
                publicHashes[index] = allDataHashes[i];
                index++;
            }
        }
        
        return publicHashes;
    }
    
    /**
     * @dev Get total number of data records
     * @return Total count
     */
    function getTotalDataCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allDataHashes.length; i++) {
            if (dataRecords[allDataHashes[i]].exists) {
                count++;
            }
        }
        return count;
    }
    
    /**
     * @dev Get data owner
     * @param dataHash The hash of the data
     * @return Owner address
     */
    function getOwner(bytes32 dataHash) external view dataExists(dataHash) returns (address) {
        return dataRecords[dataHash].owner;
    }
    
    /**
     * @dev Check if data is public
     * @param dataHash The hash of the data
     * @return True if public
     */
    function isPublic(bytes32 dataHash) external view dataExists(dataHash) returns (bool) {
        return dataRecords[dataHash].isPublic;
    }
    
    /**
     * @dev Check if data is shared with a specific user
     * @param dataHash The hash of the data
     * @param user The user address
     * @return True if shared
     */
    function isSharedWith(bytes32 dataHash, address user) external view dataExists(dataHash) returns (bool) {
        return sharedWith[dataHash][user];
    }
    
    /**
     * @dev Get all data hashes (accessible by contract owner)
     * @return Array of all data hashes
     */
    function getAllDataHashes() external view onlyContractOwner returns (bytes32[] memory) {
        return allDataHashes;
    }
    
    /**
     * @dev Transfer contract ownership
     * @param newOwner The new contract owner address
     */
    function transferContractOwnership(address newOwner) external onlyContractOwner {
        require(newOwner != address(0), "Invalid new owner address");
        contractOwner = newOwner;
    }
}
