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
        uint256 registrationTime;
        uint256 expirationTime;
        bool isActive;
    }
    
    mapping(string => NameRecord) public nameRecords;
    mapping(address => string[]) public ownerNames;
    mapping(string => bool) public nameExists;
    
    uint256 public registrationFee;
    uint256 public renewalFee;
    uint256 public registrationPeriod;
    address public owner;
    
    // Events
    event NameRegistered(string indexed name, address indexed owner, address indexed resolvedAddress, uint256 expirationTime);
    event NameRenewed(string indexed name, uint256 newExpirationTime);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event AddressUpdated(string indexed name, address indexed oldAddress, address indexed newAddress);
    event NameReleased(string indexed name, address indexed owner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyNameOwner(string memory _name) {
        require(nameRecords[_name].owner == msg.sender, "Only name owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the name service
     * @param _registrationFee The fee to register a name
     * @param _renewalFee The fee to renew a name
     * @param _registrationPeriod The registration period in seconds
     */
    constructor(uint256 _registrationFee, uint256 _renewalFee, uint256 _registrationPeriod) {
        owner = msg.sender;
        registrationFee = _registrationFee;
        renewalFee = _renewalFee;
        registrationPeriod = _registrationPeriod;
    }
    
    /**
     * @dev Registers a new name
     * @param _name The name to register
     * @param _resolvedAddress The address the name should resolve to
     */
    function registerName(string memory _name, address _resolvedAddress) external payable {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_name).length <= 32, "Name too long");
        require(_resolvedAddress != address(0), "Invalid resolved address");
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!nameExists[_name] || !nameRecords[_name].isActive || block.timestamp > nameRecords[_name].expirationTime, 
                "Name already registered");
        
        uint256 expirationTime = block.timestamp + registrationPeriod;
        
        nameRecords[_name] = NameRecord({
            owner: msg.sender,
            resolvedAddress: _resolvedAddress,
            registrationTime: block.timestamp,
            expirationTime: expirationTime,
            isActive: true
        });
        
        nameExists[_name] = true;
        ownerNames[msg.sender].push(_name);
        
        emit NameRegistered(_name, msg.sender, _resolvedAddress, expirationTime);
    }
    
    /**
     * @dev Renews a name registration
     * @param _name The name to renew
     */
    function renewName(string memory _name) external payable onlyNameOwner(_name) {
        require(msg.value >= renewalFee, "Insufficient renewal fee");
        require(nameRecords[_name].isActive, "Name is not active");
        
        NameRecord storage record = nameRecords[_name];
        
        // Extend from expiration time if not yet expired, or from current time if expired
        if (block.timestamp < record.expirationTime) {
            record.expirationTime += registrationPeriod;
        } else {
            record.expirationTime = block.timestamp + registrationPeriod;
        }
        
        emit NameRenewed(_name, record.expirationTime);
    }
    
    /**
     * @dev Updates the resolved address for a name
     * @param _name The name to update
     * @param _newAddress The new address
     */
    function updateAddress(string memory _name, address _newAddress) external onlyNameOwner(_name) {
        require(_newAddress != address(0), "Invalid address");
        require(nameRecords[_name].isActive, "Name is not active");
        require(block.timestamp < nameRecords[_name].expirationTime, "Name has expired");
        
        address oldAddress = nameRecords[_name].resolvedAddress;
        nameRecords[_name].resolvedAddress = _newAddress;
        
        emit AddressUpdated(_name, oldAddress, _newAddress);
    }
    
    /**
     * @dev Transfers name ownership to another address
     * @param _name The name to transfer
     * @param _newOwner The new owner's address
     */
    function transferName(string memory _name, address _newOwner) external onlyNameOwner(_name) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to self");
        require(nameRecords[_name].isActive, "Name is not active");
        require(block.timestamp < nameRecords[_name].expirationTime, "Name has expired");
        
        address oldOwner = nameRecords[_name].owner;
        nameRecords[_name].owner = _newOwner;
        ownerNames[_newOwner].push(_name);
        
        emit NameTransferred(_name, oldOwner, _newOwner);
    }
    
    /**
     * @dev Releases a name (deactivates it)
     * @param _name The name to release
     */
    function releaseName(string memory _name) external onlyNameOwner(_name) {
        require(nameRecords[_name].isActive, "Name is not active");
        
        nameRecords[_name].isActive = false;
        
        emit NameReleased(_name, msg.sender);
    }
    
    /**
     * @dev Resolves a name to an address
     * @param _name The name to resolve
     * @return The resolved address
     */
    function resolve(string memory _name) external view returns (address) {
        require(nameExists[_name], "Name does not exist");
        require(nameRecords[_name].isActive, "Name is not active");
        require(block.timestamp < nameRecords[_name].expirationTime, "Name has expired");
        
        return nameRecords[_name].resolvedAddress;
    }
    
    /**
     * @dev Returns the owner of a name
     * @param _name The name to query
     * @return The owner's address
     */
    function getNameOwner(string memory _name) external view returns (address) {
        require(nameExists[_name], "Name does not exist");
        return nameRecords[_name].owner;
    }
    
    /**
     * @dev Returns the details of a name record
     * @param _name The name to query
     * @return owner The owner's address
     * @return resolvedAddress The resolved address
     * @return registrationTime When the name was registered
     * @return expirationTime When the name expires
     * @return isActive Whether the name is active
     */
    function getNameRecord(string memory _name) external view returns (
        address owner,
        address resolvedAddress,
        uint256 registrationTime,
        uint256 expirationTime,
        bool isActive
    ) {
        require(nameExists[_name], "Name does not exist");
        
        NameRecord memory record = nameRecords[_name];
        
        return (
            record.owner,
            record.resolvedAddress,
            record.registrationTime,
            record.expirationTime,
            record.isActive
        );
    }
    
    /**
     * @dev Checks if a name is available for registration
     * @param _name The name to check
     * @return True if available, false otherwise
     */
    function isNameAvailable(string memory _name) external view returns (bool) {
        if (!nameExists[_name]) {
            return true;
        }
        
        NameRecord memory record = nameRecords[_name];
        
        // Name is available if it's not active or has expired
        return !record.isActive || block.timestamp > record.expirationTime;
    }
    
    /**
     * @dev Returns all names owned by an address
     * @param _owner The address to query
     * @return Array of names
     */
    function getNamesByOwner(address _owner) external view returns (string[] memory) {
        return ownerNames[_owner];
    }
    
    /**
     * @dev Returns all names owned by the caller
     * @return Array of names
     */
    function getMyNames() external view returns (string[] memory) {
        return ownerNames[msg.sender];
    }
    
    /**
     * @dev Returns the time remaining until a name expires
     * @param _name The name to check
     * @return Time remaining in seconds, or 0 if expired
     */
    function getTimeUntilExpiration(string memory _name) external view returns (uint256) {
        require(nameExists[_name], "Name does not exist");
        
        NameRecord memory record = nameRecords[_name];
        
        if (!record.isActive || block.timestamp >= record.expirationTime) {
            return 0;
        }
        
        return record.expirationTime - block.timestamp;
    }
    
    /**
     * @dev Checks if a name is expired
     * @param _name The name to check
     * @return True if expired, false otherwise
     */
    function isNameExpired(string memory _name) external view returns (bool) {
        require(nameExists[_name], "Name does not exist");
        
        return block.timestamp >= nameRecords[_name].expirationTime;
    }
    
    /**
     * @dev Updates the registration fee (only owner)
     * @param _newFee The new registration fee
     */
    function updateRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
    }
    
    /**
     * @dev Updates the renewal fee (only owner)
     * @param _newFee The new renewal fee
     */
    function updateRenewalFee(uint256 _newFee) external onlyOwner {
        renewalFee = _newFee;
    }
    
    /**
     * @dev Updates the registration period (only owner)
     * @param _newPeriod The new registration period in seconds
     */
    function updateRegistrationPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "Period must be greater than 0");
        registrationPeriod = _newPeriod;
    }
    
    /**
     * @dev Allows the owner to withdraw collected fees
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Allows the owner to withdraw a specific amount
     * @param _amount The amount to withdraw
     */
    function withdrawAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Returns the contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
