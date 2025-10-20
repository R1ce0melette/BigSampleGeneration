// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DecentralizedNameService
 * @dev A basic decentralized name service where names map to wallet addresses
 */
contract DecentralizedNameService {
    struct NameRecord {
        address owner;
        address resolvedAddress;
        uint256 registeredAt;
        uint256 expiresAt;
        bool exists;
    }
    
    mapping(string => NameRecord) public nameRecords;
    mapping(address => string[]) public addressToNames;
    
    uint256 public registrationFee = 0.01 ether;
    uint256 public registrationPeriod = 365 days;
    
    address public owner;
    
    // Events
    event NameRegistered(string indexed name, address indexed owner, address indexed resolvedAddress, uint256 expiresAt);
    event NameRenewed(string indexed name, address indexed owner, uint256 newExpiresAt);
    event NameTransferred(string indexed name, address indexed previousOwner, address indexed newOwner);
    event AddressUpdated(string indexed name, address indexed oldAddress, address indexed newAddress);
    event NameReleased(string indexed name, address indexed previousOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyNameOwner(string memory name) {
        require(nameRecords[name].exists, "Name does not exist");
        require(nameRecords[name].owner == msg.sender, "Not the name owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new name
     * @param name The name to register
     * @param resolvedAddress The address the name should resolve to
     */
    function registerName(string memory name, address resolvedAddress) external payable {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 50, "Name too long");
        require(resolvedAddress != address(0), "Invalid resolved address");
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!nameRecords[name].exists || block.timestamp > nameRecords[name].expiresAt, "Name already registered");
        
        // If name was previously registered and expired, remove from old owner's list
        if (nameRecords[name].exists) {
            _removeNameFromOwner(nameRecords[name].owner, name);
        }
        
        uint256 expiresAt = block.timestamp + registrationPeriod;
        
        nameRecords[name] = NameRecord({
            owner: msg.sender,
            resolvedAddress: resolvedAddress,
            registeredAt: block.timestamp,
            expiresAt: expiresAt,
            exists: true
        });
        
        addressToNames[msg.sender].push(name);
        
        emit NameRegistered(name, msg.sender, resolvedAddress, expiresAt);
    }
    
    /**
     * @dev Renew a name registration
     * @param name The name to renew
     */
    function renewName(string memory name) external payable onlyNameOwner(name) {
        require(msg.value >= registrationFee, "Insufficient renewal fee");
        
        NameRecord storage record = nameRecords[name];
        
        // Extend from current expiry if not expired, otherwise from now
        if (block.timestamp <= record.expiresAt) {
            record.expiresAt += registrationPeriod;
        } else {
            record.expiresAt = block.timestamp + registrationPeriod;
        }
        
        emit NameRenewed(name, msg.sender, record.expiresAt);
    }
    
    /**
     * @dev Update the address a name resolves to
     * @param name The name to update
     * @param newAddress The new address
     */
    function updateAddress(string memory name, address newAddress) external onlyNameOwner(name) {
        require(newAddress != address(0), "Invalid address");
        require(block.timestamp <= nameRecords[name].expiresAt, "Name has expired");
        
        address oldAddress = nameRecords[name].resolvedAddress;
        nameRecords[name].resolvedAddress = newAddress;
        
        emit AddressUpdated(name, oldAddress, newAddress);
    }
    
    /**
     * @dev Transfer name ownership to another address
     * @param name The name to transfer
     * @param newOwner The new owner's address
     */
    function transferName(string memory name, address newOwner) external onlyNameOwner(name) {
        require(newOwner != address(0), "Invalid new owner");
        require(newOwner != msg.sender, "Cannot transfer to yourself");
        require(block.timestamp <= nameRecords[name].expiresAt, "Name has expired");
        
        address previousOwner = nameRecords[name].owner;
        nameRecords[name].owner = newOwner;
        
        // Update ownership lists
        _removeNameFromOwner(previousOwner, name);
        addressToNames[newOwner].push(name);
        
        emit NameTransferred(name, previousOwner, newOwner);
    }
    
    /**
     * @dev Release a name before expiry
     * @param name The name to release
     */
    function releaseName(string memory name) external onlyNameOwner(name) {
        address previousOwner = nameRecords[name].owner;
        
        delete nameRecords[name];
        _removeNameFromOwner(previousOwner, name);
        
        emit NameReleased(name, previousOwner);
    }
    
    /**
     * @dev Remove a name from an owner's list
     * @param ownerAddress The owner's address
     * @param name The name to remove
     */
    function _removeNameFromOwner(address ownerAddress, string memory name) internal {
        string[] storage names = addressToNames[ownerAddress];
        for (uint256 i = 0; i < names.length; i++) {
            if (keccak256(bytes(names[i])) == keccak256(bytes(name))) {
                names[i] = names[names.length - 1];
                names.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Resolve a name to an address
     * @param name The name to resolve
     * @return The resolved address
     */
    function resolve(string memory name) external view returns (address) {
        require(nameRecords[name].exists, "Name does not exist");
        require(block.timestamp <= nameRecords[name].expiresAt, "Name has expired");
        
        return nameRecords[name].resolvedAddress;
    }
    
    /**
     * @dev Get name record details
     * @param name The name to query
     * @return ownerAddress The owner's address
     * @return resolvedAddress The resolved address
     * @return registeredAt Registration timestamp
     * @return expiresAt Expiration timestamp
     * @return exists Whether the name exists
     * @return isExpired Whether the name has expired
     */
    function getNameRecord(string memory name) external view returns (
        address ownerAddress,
        address resolvedAddress,
        uint256 registeredAt,
        uint256 expiresAt,
        bool exists,
        bool isExpired
    ) {
        NameRecord memory record = nameRecords[name];
        bool expired = record.exists && block.timestamp > record.expiresAt;
        
        return (
            record.owner,
            record.resolvedAddress,
            record.registeredAt,
            record.expiresAt,
            record.exists,
            expired
        );
    }
    
    /**
     * @dev Check if a name is available for registration
     * @param name The name to check
     * @return True if available, false otherwise
     */
    function isNameAvailable(string memory name) external view returns (bool) {
        return !nameRecords[name].exists || block.timestamp > nameRecords[name].expiresAt;
    }
    
    /**
     * @dev Get all names owned by an address
     * @param ownerAddress The owner's address
     * @return Array of names
     */
    function getNamesByOwner(address ownerAddress) external view returns (string[] memory) {
        return addressToNames[ownerAddress];
    }
    
    /**
     * @dev Get active (non-expired) names owned by an address
     * @param ownerAddress The owner's address
     * @return Array of active names
     */
    function getActiveNamesByOwner(address ownerAddress) external view returns (string[] memory) {
        string[] memory allNames = addressToNames[ownerAddress];
        uint256 activeCount = 0;
        
        // Count active names
        for (uint256 i = 0; i < allNames.length; i++) {
            if (nameRecords[allNames[i]].exists && block.timestamp <= nameRecords[allNames[i]].expiresAt) {
                activeCount++;
            }
        }
        
        // Collect active names
        string[] memory activeNames = new string[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allNames.length; i++) {
            if (nameRecords[allNames[i]].exists && block.timestamp <= nameRecords[allNames[i]].expiresAt) {
                activeNames[index] = allNames[i];
                index++;
            }
        }
        
        return activeNames;
    }
    
    /**
     * @dev Get the time remaining until a name expires
     * @param name The name to check
     * @return Time remaining in seconds (0 if expired)
     */
    function getTimeUntilExpiry(string memory name) external view returns (uint256) {
        require(nameRecords[name].exists, "Name does not exist");
        
        if (block.timestamp >= nameRecords[name].expiresAt) {
            return 0;
        }
        
        return nameRecords[name].expiresAt - block.timestamp;
    }
    
    /**
     * @dev Update registration fee (owner only)
     * @param newFee The new registration fee
     */
    function updateRegistrationFee(uint256 newFee) external onlyOwner {
        registrationFee = newFee;
    }
    
    /**
     * @dev Update registration period (owner only)
     * @param newPeriod The new registration period in seconds
     */
    function updateRegistrationPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Period must be greater than 0");
        registrationPeriod = newPeriod;
    }
    
    /**
     * @dev Withdraw collected fees (owner only)
     * @param amount Amount to withdraw (0 to withdraw all)
     */
    function withdrawFees(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        uint256 withdrawAmount = amount == 0 ? balance : amount;
        require(withdrawAmount <= balance, "Insufficient balance");
        
        (bool success, ) = owner.call{value: withdrawAmount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer contract ownership
     * @param newOwner The new owner's address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
}
