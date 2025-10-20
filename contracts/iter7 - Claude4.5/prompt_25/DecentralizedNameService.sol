// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DecentralizedNameService
 * @dev A basic decentralized name service where names map to wallet addresses
 */
contract DecentralizedNameService {
    address public owner;
    
    // Name registration structure
    struct NameRecord {
        address owner;
        uint256 registeredAt;
        uint256 expiresAt;
        bool exists;
    }
    
    // State variables
    mapping(string => NameRecord) public nameRecords;
    mapping(address => string[]) public addressToNames;
    mapping(string => address) public nameToAddress;
    
    // Registration settings
    uint256 public registrationFee = 0.01 ether;
    uint256 public registrationPeriod = 365 days;
    uint256 public renewalFee = 0.005 ether;
    
    // Events
    event NameRegistered(string indexed name, address indexed owner, uint256 expiresAt, uint256 timestamp);
    event NameRenewed(string indexed name, address indexed owner, uint256 newExpiresAt, uint256 timestamp);
    event NameTransferred(string indexed name, address indexed from, address indexed to, uint256 timestamp);
    event NameReleased(string indexed name, address indexed previousOwner, uint256 timestamp);
    event RegistrationFeeUpdated(uint256 oldFee, uint256 newFee);
    event RenewalFeeUpdated(uint256 oldFee, uint256 newFee);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier validName(string memory name) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 32, "Name too long");
        _;
    }
    
    /**
     * @dev Constructor sets the contract owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new name
     * @param name The name to register
     */
    function registerName(string memory name) external payable validName(name) {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!isNameActive(name), "Name already registered and active");
        
        // If name existed before but expired, clean up old mapping
        if (nameRecords[name].exists) {
            address previousOwner = nameRecords[name].owner;
            _removeNameFromAddress(previousOwner, name);
        }
        
        nameRecords[name] = NameRecord({
            owner: msg.sender,
            registeredAt: block.timestamp,
            expiresAt: block.timestamp + registrationPeriod,
            exists: true
        });
        
        nameToAddress[name] = msg.sender;
        addressToNames[msg.sender].push(name);
        
        emit NameRegistered(name, msg.sender, nameRecords[name].expiresAt, block.timestamp);
        
        // Refund excess payment
        if (msg.value > registrationFee) {
            (bool success, ) = msg.sender.call{value: msg.value - registrationFee}("");
            require(success, "Refund failed");
        }
    }
    
    /**
     * @dev Renew a name registration
     * @param name The name to renew
     */
    function renewName(string memory name) external payable validName(name) {
        require(msg.value >= renewalFee, "Insufficient renewal fee");
        require(nameRecords[name].exists, "Name not registered");
        require(nameRecords[name].owner == msg.sender, "Only name owner can renew");
        
        // Extend expiration from current expiry or now, whichever is later
        uint256 extendFrom = block.timestamp > nameRecords[name].expiresAt ? block.timestamp : nameRecords[name].expiresAt;
        nameRecords[name].expiresAt = extendFrom + registrationPeriod;
        
        emit NameRenewed(name, msg.sender, nameRecords[name].expiresAt, block.timestamp);
        
        // Refund excess payment
        if (msg.value > renewalFee) {
            (bool success, ) = msg.sender.call{value: msg.value - renewalFee}("");
            require(success, "Refund failed");
        }
    }
    
    /**
     * @dev Transfer name ownership to another address
     * @param name The name to transfer
     * @param newOwner The address of the new owner
     */
    function transferName(string memory name, address newOwner) external validName(name) {
        require(newOwner != address(0), "Invalid new owner address");
        require(nameRecords[name].exists, "Name not registered");
        require(nameRecords[name].owner == msg.sender, "Only name owner can transfer");
        require(isNameActive(name), "Name has expired");
        
        address previousOwner = nameRecords[name].owner;
        
        // Remove from previous owner's list
        _removeNameFromAddress(previousOwner, name);
        
        // Update ownership
        nameRecords[name].owner = newOwner;
        nameToAddress[name] = newOwner;
        addressToNames[newOwner].push(name);
        
        emit NameTransferred(name, previousOwner, newOwner, block.timestamp);
    }
    
    /**
     * @dev Release a name (give up ownership)
     * @param name The name to release
     */
    function releaseName(string memory name) external validName(name) {
        require(nameRecords[name].exists, "Name not registered");
        require(nameRecords[name].owner == msg.sender, "Only name owner can release");
        
        address previousOwner = nameRecords[name].owner;
        
        // Remove from owner's list
        _removeNameFromAddress(previousOwner, name);
        
        // Mark as expired
        nameRecords[name].expiresAt = block.timestamp;
        delete nameToAddress[name];
        
        emit NameReleased(name, previousOwner, block.timestamp);
    }
    
    /**
     * @dev Internal function to remove a name from an address's list
     * @param addr The address
     * @param name The name to remove
     */
    function _removeNameFromAddress(address addr, string memory name) internal {
        string[] storage names = addressToNames[addr];
        
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
     * @return The address associated with the name
     */
    function resolveName(string memory name) external view validName(name) returns (address) {
        require(isNameActive(name), "Name not active");
        return nameToAddress[name];
    }
    
    /**
     * @dev Check if a name is currently active (registered and not expired)
     * @param name The name to check
     * @return True if the name is active, false otherwise
     */
    function isNameActive(string memory name) public view returns (bool) {
        if (!nameRecords[name].exists) {
            return false;
        }
        return block.timestamp < nameRecords[name].expiresAt;
    }
    
    /**
     * @dev Check if a name is available for registration
     * @param name The name to check
     * @return True if available, false otherwise
     */
    function isNameAvailable(string memory name) external view validName(name) returns (bool) {
        return !isNameActive(name);
    }
    
    /**
     * @dev Get name record details
     * @param name The name to query
     * @return nameOwner The owner's address
     * @return registeredAt Registration timestamp
     * @return expiresAt Expiration timestamp
     * @return exists Whether the record exists
     * @return active Whether the name is currently active
     */
    function getNameRecord(string memory name) external view validName(name) returns (
        address nameOwner,
        uint256 registeredAt,
        uint256 expiresAt,
        bool exists,
        bool active
    ) {
        NameRecord memory record = nameRecords[name];
        return (
            record.owner,
            record.registeredAt,
            record.expiresAt,
            record.exists,
            isNameActive(name)
        );
    }
    
    /**
     * @dev Get all names registered by an address
     * @param addr The address to query
     * @return Array of names
     */
    function getNamesByAddress(address addr) external view returns (string[] memory) {
        return addressToNames[addr];
    }
    
    /**
     * @dev Get all active names registered by an address
     * @param addr The address to query
     * @return Array of active names
     */
    function getActiveNamesByAddress(address addr) external view returns (string[] memory) {
        string[] memory allNames = addressToNames[addr];
        uint256 activeCount = 0;
        
        // Count active names
        for (uint256 i = 0; i < allNames.length; i++) {
            if (isNameActive(allNames[i])) {
                activeCount++;
            }
        }
        
        // Create array of active names
        string[] memory activeNames = new string[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allNames.length; i++) {
            if (isNameActive(allNames[i])) {
                activeNames[index] = allNames[i];
                index++;
            }
        }
        
        return activeNames;
    }
    
    /**
     * @dev Get time remaining until a name expires
     * @param name The name to check
     * @return The time remaining in seconds, or 0 if expired/not registered
     */
    function getTimeUntilExpiry(string memory name) external view validName(name) returns (uint256) {
        if (!nameRecords[name].exists) {
            return 0;
        }
        
        if (block.timestamp >= nameRecords[name].expiresAt) {
            return 0;
        }
        
        return nameRecords[name].expiresAt - block.timestamp;
    }
    
    /**
     * @dev Get caller's registered names
     * @return Array of names
     */
    function getMyNames() external view returns (string[] memory) {
        return addressToNames[msg.sender];
    }
    
    /**
     * @dev Update registration fee (only owner)
     * @param newFee The new registration fee
     */
    function setRegistrationFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = registrationFee;
        registrationFee = newFee;
        
        emit RegistrationFeeUpdated(oldFee, newFee);
    }
    
    /**
     * @dev Update renewal fee (only owner)
     * @param newFee The new renewal fee
     */
    function setRenewalFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = renewalFee;
        renewalFee = newFee;
        
        emit RenewalFeeUpdated(oldFee, newFee);
    }
    
    /**
     * @dev Update registration period (only owner)
     * @param newPeriod The new registration period in seconds
     */
    function setRegistrationPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Period must be greater than 0");
        registrationPeriod = newPeriod;
    }
    
    /**
     * @dev Withdraw collected fees (only owner)
     * @param amount The amount to withdraw
     */
    function withdrawFees(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Withdraw all collected fees (only owner)
     */
    function withdrawAllFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
