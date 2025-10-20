// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    struct NameRecord {
        address owner;
        address resolvedAddress;
        uint256 registeredAt;
        uint256 expiresAt;
        bool exists;
    }
    
    mapping(string => NameRecord) public names;
    mapping(address => string[]) public ownerNames;
    
    uint256 public registrationFee = 0.01 ether;
    uint256 public renewalFee = 0.005 ether;
    uint256 public registrationPeriod = 365 days;
    
    address public owner;
    
    // Events
    event NameRegistered(string indexed name, address indexed owner, address resolvedAddress, uint256 expiresAt);
    event NameRenewed(string indexed name, uint256 newExpiresAt);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event AddressUpdated(string indexed name, address indexed newAddress);
    event NameReleased(string indexed name);
    event FeesUpdated(uint256 registrationFee, uint256 renewalFee);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyNameOwner(string memory _name) {
        require(names[_name].exists, "Name does not exist");
        require(names[_name].owner == msg.sender, "Only name owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new name
     * @param _name The name to register
     * @param _resolvedAddress The address to resolve to
     */
    function registerName(string memory _name, address _resolvedAddress) external payable {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_name).length <= 50, "Name too long");
        require(_resolvedAddress != address(0), "Invalid resolved address");
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!names[_name].exists || block.timestamp > names[_name].expiresAt, "Name already registered");
        
        uint256 expiresAt = block.timestamp + registrationPeriod;
        
        names[_name] = NameRecord({
            owner: msg.sender,
            resolvedAddress: _resolvedAddress,
            registeredAt: block.timestamp,
            expiresAt: expiresAt,
            exists: true
        });
        
        ownerNames[msg.sender].push(_name);
        
        emit NameRegistered(_name, msg.sender, _resolvedAddress, expiresAt);
    }
    
    /**
     * @dev Renew a name registration
     * @param _name The name to renew
     */
    function renewName(string memory _name) external payable onlyNameOwner(_name) {
        require(msg.value >= renewalFee, "Insufficient renewal fee");
        
        NameRecord storage record = names[_name];
        
        // If expired, renew from current time, otherwise extend from expiry
        if (block.timestamp > record.expiresAt) {
            record.expiresAt = block.timestamp + registrationPeriod;
        } else {
            record.expiresAt += registrationPeriod;
        }
        
        emit NameRenewed(_name, record.expiresAt);
    }
    
    /**
     * @dev Transfer name ownership to another address
     * @param _name The name to transfer
     * @param _newOwner The new owner address
     */
    function transferName(string memory _name, address _newOwner) external onlyNameOwner(_name) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        require(block.timestamp <= names[_name].expiresAt, "Name has expired");
        
        NameRecord storage record = names[_name];
        address previousOwner = record.owner;
        
        record.owner = _newOwner;
        ownerNames[_newOwner].push(_name);
        
        emit NameTransferred(_name, previousOwner, _newOwner);
    }
    
    /**
     * @dev Update the resolved address for a name
     * @param _name The name to update
     * @param _newAddress The new address to resolve to
     */
    function updateAddress(string memory _name, address _newAddress) external onlyNameOwner(_name) {
        require(_newAddress != address(0), "Invalid address");
        require(block.timestamp <= names[_name].expiresAt, "Name has expired");
        
        names[_name].resolvedAddress = _newAddress;
        
        emit AddressUpdated(_name, _newAddress);
    }
    
    /**
     * @dev Release a name (delete registration)
     * @param _name The name to release
     */
    function releaseName(string memory _name) external onlyNameOwner(_name) {
        delete names[_name];
        
        emit NameReleased(_name);
    }
    
    /**
     * @dev Resolve a name to an address
     * @param _name The name to resolve
     * @return The resolved address
     */
    function resolve(string memory _name) external view returns (address) {
        require(names[_name].exists, "Name does not exist");
        require(block.timestamp <= names[_name].expiresAt, "Name has expired");
        
        return names[_name].resolvedAddress;
    }
    
    /**
     * @dev Check if a name is available
     * @param _name The name to check
     * @return True if available, false otherwise
     */
    function isAvailable(string memory _name) external view returns (bool) {
        return !names[_name].exists || block.timestamp > names[_name].expiresAt;
    }
    
    /**
     * @dev Get name record details
     * @param _name The name to query
     * @return owner The owner address
     * @return resolvedAddress The resolved address
     * @return registeredAt The registration timestamp
     * @return expiresAt The expiration timestamp
     * @return isActive Whether the name is currently active
     */
    function getNameRecord(string memory _name) external view returns (
        address owner_,
        address resolvedAddress,
        uint256 registeredAt,
        uint256 expiresAt,
        bool isActive
    ) {
        require(names[_name].exists, "Name does not exist");
        
        NameRecord memory record = names[_name];
        
        return (
            record.owner,
            record.resolvedAddress,
            record.registeredAt,
            record.expiresAt,
            block.timestamp <= record.expiresAt
        );
    }
    
    /**
     * @dev Get all names owned by an address
     * @param _owner The owner address
     * @return Array of names
     */
    function getNamesByOwner(address _owner) external view returns (string[] memory) {
        return ownerNames[_owner];
    }
    
    /**
     * @dev Get active names owned by an address
     * @param _owner The owner address
     * @return Array of active names
     */
    function getActiveNamesByOwner(address _owner) external view returns (string[] memory) {
        string[] memory allNames = ownerNames[_owner];
        uint256 activeCount = 0;
        
        // Count active names
        for (uint256 i = 0; i < allNames.length; i++) {
            if (names[allNames[i]].exists && 
                names[allNames[i]].owner == _owner && 
                block.timestamp <= names[allNames[i]].expiresAt) {
                activeCount++;
            }
        }
        
        string[] memory activeNames = new string[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allNames.length; i++) {
            if (names[allNames[i]].exists && 
                names[allNames[i]].owner == _owner && 
                block.timestamp <= names[allNames[i]].expiresAt) {
                activeNames[index] = allNames[i];
                index++;
            }
        }
        
        return activeNames;
    }
    
    /**
     * @dev Check if a name is expired
     * @param _name The name to check
     * @return True if expired, false otherwise
     */
    function isExpired(string memory _name) external view returns (bool) {
        if (!names[_name].exists) {
            return false;
        }
        return block.timestamp > names[_name].expiresAt;
    }
    
    /**
     * @dev Get time until expiration
     * @param _name The name to check
     * @return Time remaining in seconds (0 if expired)
     */
    function getTimeUntilExpiration(string memory _name) external view returns (uint256) {
        require(names[_name].exists, "Name does not exist");
        
        if (block.timestamp >= names[_name].expiresAt) {
            return 0;
        }
        
        return names[_name].expiresAt - block.timestamp;
    }
    
    /**
     * @dev Update registration and renewal fees
     * @param _registrationFee New registration fee
     * @param _renewalFee New renewal fee
     */
    function updateFees(uint256 _registrationFee, uint256 _renewalFee) external onlyOwner {
        require(_registrationFee > 0, "Registration fee must be greater than 0");
        require(_renewalFee > 0, "Renewal fee must be greater than 0");
        
        registrationFee = _registrationFee;
        renewalFee = _renewalFee;
        
        emit FeesUpdated(_registrationFee, _renewalFee);
    }
    
    /**
     * @dev Update registration period
     * @param _period New registration period in seconds
     */
    function updateRegistrationPeriod(uint256 _period) external onlyOwner {
        require(_period > 0, "Period must be greater than 0");
        
        registrationPeriod = _period;
    }
    
    /**
     * @dev Withdraw collected fees
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer ownership of the contract
     * @param _newOwner The new owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        
        owner = _newOwner;
    }
}
