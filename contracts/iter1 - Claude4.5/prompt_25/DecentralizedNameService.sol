// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DecentralizedNameService
 * @dev A basic decentralized name service where names map to wallet addresses
 */
contract DecentralizedNameService {
    address public owner;
    
    struct NameRecord {
        address owner;
        address resolvedAddress;
        uint256 registeredAt;
        uint256 expiresAt;
        bool exists;
    }
    
    mapping(string => NameRecord) private nameRecords;
    mapping(address => string[]) private addressToNames;
    mapping(string => bool) private nameExists;
    
    uint256 public registrationFee = 0.01 ether;
    uint256 public constant REGISTRATION_PERIOD = 365 days;
    
    event NameRegistered(
        string indexed name,
        address indexed owner,
        address resolvedAddress,
        uint256 expiresAt
    );
    
    event NameRenewed(
        string indexed name,
        address indexed owner,
        uint256 newExpiresAt
    );
    
    event NameTransferred(
        string indexed name,
        address indexed from,
        address indexed to
    );
    
    event AddressUpdated(
        string indexed name,
        address indexed oldAddress,
        address indexed newAddress
    );
    
    event NameReleased(string indexed name, address indexed owner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
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
        require(bytes(name).length <= 32, "Name too long");
        require(resolvedAddress != address(0), "Invalid resolved address");
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!nameExists[name] || block.timestamp >= nameRecords[name].expiresAt, "Name already registered");
        
        // If name existed before and expired, release it first
        if (nameExists[name] && block.timestamp >= nameRecords[name].expiresAt) {
            _releaseName(name);
        }
        
        uint256 expiresAt = block.timestamp + REGISTRATION_PERIOD;
        
        nameRecords[name] = NameRecord({
            owner: msg.sender,
            resolvedAddress: resolvedAddress,
            registeredAt: block.timestamp,
            expiresAt: expiresAt,
            exists: true
        });
        
        nameExists[name] = true;
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
        
        // Extend from current expiry or from now if already expired
        if (block.timestamp < record.expiresAt) {
            record.expiresAt += REGISTRATION_PERIOD;
        } else {
            record.expiresAt = block.timestamp + REGISTRATION_PERIOD;
        }
        
        emit NameRenewed(name, msg.sender, record.expiresAt);
    }
    
    /**
     * @dev Transfer name ownership to another address
     * @param name The name to transfer
     * @param newOwner The address of the new owner
     */
    function transferName(string memory name, address newOwner) external onlyNameOwner(name) {
        require(newOwner != address(0), "Invalid new owner");
        require(block.timestamp < nameRecords[name].expiresAt, "Name has expired");
        
        address oldOwner = nameRecords[name].owner;
        nameRecords[name].owner = newOwner;
        
        addressToNames[newOwner].push(name);
        
        emit NameTransferred(name, oldOwner, newOwner);
    }
    
    /**
     * @dev Update the address a name resolves to
     * @param name The name to update
     * @param newAddress The new address
     */
    function updateAddress(string memory name, address newAddress) external onlyNameOwner(name) {
        require(newAddress != address(0), "Invalid address");
        require(block.timestamp < nameRecords[name].expiresAt, "Name has expired");
        
        address oldAddress = nameRecords[name].resolvedAddress;
        nameRecords[name].resolvedAddress = newAddress;
        
        emit AddressUpdated(name, oldAddress, newAddress);
    }
    
    /**
     * @dev Release a name (voluntarily)
     * @param name The name to release
     */
    function releaseName(string memory name) external onlyNameOwner(name) {
        _releaseName(name);
        emit NameReleased(name, msg.sender);
    }
    
    /**
     * @dev Internal function to release a name
     * @param name The name to release
     */
    function _releaseName(string memory name) private {
        delete nameRecords[name];
        nameExists[name] = false;
    }
    
    /**
     * @dev Resolve a name to an address
     * @param name The name to resolve
     * @return The resolved address
     */
    function resolve(string memory name) external view returns (address) {
        require(nameRecords[name].exists, "Name not registered");
        require(block.timestamp < nameRecords[name].expiresAt, "Name has expired");
        
        return nameRecords[name].resolvedAddress;
    }
    
    /**
     * @dev Get name record details
     * @param name The name to query
     * @return _owner Owner of the name
     * @return resolvedAddress Address the name resolves to
     * @return registeredAt Registration timestamp
     * @return expiresAt Expiration timestamp
     * @return exists Whether the name exists
     */
    function getNameRecord(string memory name) external view returns (
        address _owner,
        address resolvedAddress,
        uint256 registeredAt,
        uint256 expiresAt,
        bool exists
    ) {
        NameRecord memory record = nameRecords[name];
        
        return (
            record.owner,
            record.resolvedAddress,
            record.registeredAt,
            record.expiresAt,
            record.exists
        );
    }
    
    /**
     * @dev Check if a name is available for registration
     * @param name The name to check
     * @return Whether the name is available
     */
    function isNameAvailable(string memory name) external view returns (bool) {
        if (!nameExists[name]) {
            return true;
        }
        
        return block.timestamp >= nameRecords[name].expiresAt;
    }
    
    /**
     * @dev Check if a name is registered and valid
     * @param name The name to check
     * @return Whether the name is valid
     */
    function isNameValid(string memory name) external view returns (bool) {
        return nameRecords[name].exists && block.timestamp < nameRecords[name].expiresAt;
    }
    
    /**
     * @dev Get all names owned by an address
     * @param _owner The address to query
     * @return Array of names
     */
    function getNamesByOwner(address _owner) external view returns (string[] memory) {
        uint256 count = 0;
        
        // Count valid names
        for (uint256 i = 0; i < addressToNames[_owner].length; i++) {
            string memory name = addressToNames[_owner][i];
            if (nameRecords[name].owner == _owner && 
                nameRecords[name].exists && 
                block.timestamp < nameRecords[name].expiresAt) {
                count++;
            }
        }
        
        // Create array and populate
        string[] memory ownedNames = new string[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < addressToNames[_owner].length; i++) {
            string memory name = addressToNames[_owner][i];
            if (nameRecords[name].owner == _owner && 
                nameRecords[name].exists && 
                block.timestamp < nameRecords[name].expiresAt) {
                ownedNames[index] = name;
                index++;
            }
        }
        
        return ownedNames;
    }
    
    /**
     * @dev Get time remaining until name expiration
     * @param name The name to check
     * @return Time remaining in seconds (0 if expired or doesn't exist)
     */
    function getTimeUntilExpiration(string memory name) external view returns (uint256) {
        if (!nameRecords[name].exists) {
            return 0;
        }
        
        if (block.timestamp >= nameRecords[name].expiresAt) {
            return 0;
        }
        
        return nameRecords[name].expiresAt - block.timestamp;
    }
    
    /**
     * @dev Get the owner of a name
     * @param name The name to query
     * @return The owner address
     */
    function getNameOwner(string memory name) external view returns (address) {
        require(nameRecords[name].exists, "Name not registered");
        return nameRecords[name].owner;
    }
    
    /**
     * @dev Update registration fee (only owner)
     * @param newFee The new registration fee
     */
    function updateRegistrationFee(uint256 newFee) external onlyOwner {
        require(newFee > 0, "Fee must be greater than 0");
        registrationFee = newFee;
    }
    
    /**
     * @dev Withdraw contract balance (only owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Withdraw specific amount (only owner)
     * @param amount The amount to withdraw
     */
    function withdrawAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer contract ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}
