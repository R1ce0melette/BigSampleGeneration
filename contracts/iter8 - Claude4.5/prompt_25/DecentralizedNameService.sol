// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DecentralizedNameService
 * @dev Basic decentralized name service where names map to wallet addresses
 */
contract DecentralizedNameService {
    // Name record structure
    struct NameRecord {
        string name;
        address owner;
        address resolvedAddress;
        uint256 registeredAt;
        uint256 expiryTime;
        bool active;
        string metadata;
    }

    // Owner statistics
    struct OwnerStats {
        uint256 namesOwned;
        uint256 totalNamesRegistered;
        uint256 totalNamesTransferred;
    }

    // State variables
    address public owner;
    uint256 public registrationFee;
    uint256 public renewalFee;
    uint256 public registrationPeriod; // Duration in seconds
    
    mapping(string => NameRecord) private nameRecords;
    mapping(address => string[]) private ownerNames;
    mapping(string => bool) private nameExists;
    mapping(address => OwnerStats) private ownerStats;
    mapping(address => string) private primaryName; // Primary name for reverse lookup
    
    string[] private allNames;
    uint256 public totalNamesRegistered;

    // Events
    event NameRegistered(string indexed name, address indexed owner, uint256 expiryTime);
    event NameRenewed(string indexed name, address indexed owner, uint256 newExpiryTime);
    event NameTransferred(string indexed name, address indexed fromOwner, address indexed toOwner);
    event NameReleased(string indexed name, address indexed owner);
    event AddressUpdated(string indexed name, address indexed newAddress);
    event MetadataUpdated(string indexed name, string metadata);
    event PrimaryNameSet(address indexed owner, string name);
    event FeesUpdated(uint256 registrationFee, uint256 renewalFee);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier nameRegistered(string memory name) {
        require(nameExists[name], "Name not registered");
        _;
    }

    modifier onlyNameOwner(string memory name) {
        require(nameRecords[name].owner == msg.sender, "Not the name owner");
        _;
    }

    modifier validName(string memory name) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 32, "Name too long");
        _;
    }

    constructor(
        uint256 _registrationFee,
        uint256 _renewalFee,
        uint256 _registrationPeriod
    ) {
        owner = msg.sender;
        registrationFee = _registrationFee;
        renewalFee = _renewalFee;
        registrationPeriod = _registrationPeriod;
        totalNamesRegistered = 0;
    }

    /**
     * @dev Register a new name
     * @param name Name to register
     * @param resolvedAddress Address to resolve to
     * @param metadata Optional metadata
     */
    function registerName(
        string memory name,
        address resolvedAddress,
        string memory metadata
    ) public payable validName(name) {
        require(!nameExists[name], "Name already registered");
        require(resolvedAddress != address(0), "Invalid resolved address");
        require(msg.value >= registrationFee, "Insufficient registration fee");

        uint256 expiryTime = block.timestamp + registrationPeriod;

        nameRecords[name] = NameRecord({
            name: name,
            owner: msg.sender,
            resolvedAddress: resolvedAddress,
            registeredAt: block.timestamp,
            expiryTime: expiryTime,
            active: true,
            metadata: metadata
        });

        nameExists[name] = true;
        ownerNames[msg.sender].push(name);
        allNames.push(name);

        ownerStats[msg.sender].namesOwned++;
        ownerStats[msg.sender].totalNamesRegistered++;
        totalNamesRegistered++;

        // Set as primary name if user doesn't have one
        if (bytes(primaryName[msg.sender]).length == 0) {
            primaryName[msg.sender] = name;
        }

        emit NameRegistered(name, msg.sender, expiryTime);
    }

    /**
     * @dev Renew a name registration
     * @param name Name to renew
     */
    function renewName(string memory name) 
        public 
        payable 
        nameRegistered(name)
        onlyNameOwner(name)
    {
        require(msg.value >= renewalFee, "Insufficient renewal fee");

        NameRecord storage record = nameRecords[name];
        
        // Extend from current expiry or current time, whichever is later
        uint256 baseTime = record.expiryTime > block.timestamp ? record.expiryTime : block.timestamp;
        record.expiryTime = baseTime + registrationPeriod;

        emit NameRenewed(name, msg.sender, record.expiryTime);
    }

    /**
     * @dev Transfer name ownership
     * @param name Name to transfer
     * @param newOwner New owner address
     */
    function transferName(string memory name, address newOwner) 
        public 
        nameRegistered(name)
        onlyNameOwner(name)
    {
        require(newOwner != address(0), "Invalid new owner");
        require(newOwner != msg.sender, "Cannot transfer to yourself");

        NameRecord storage record = nameRecords[name];
        address previousOwner = record.owner;

        record.owner = newOwner;
        ownerNames[newOwner].push(name);

        ownerStats[previousOwner].namesOwned--;
        ownerStats[previousOwner].totalNamesTransferred++;
        ownerStats[newOwner].namesOwned++;
        ownerStats[newOwner].totalNamesRegistered++;

        // Clear primary name if it was the transferred name
        if (keccak256(bytes(primaryName[previousOwner])) == keccak256(bytes(name))) {
            delete primaryName[previousOwner];
        }

        // Set as primary for new owner if they don't have one
        if (bytes(primaryName[newOwner]).length == 0) {
            primaryName[newOwner] = name;
        }

        emit NameTransferred(name, previousOwner, newOwner);
    }

    /**
     * @dev Update the resolved address for a name
     * @param name Name to update
     * @param newAddress New resolved address
     */
    function updateAddress(string memory name, address newAddress) 
        public 
        nameRegistered(name)
        onlyNameOwner(name)
    {
        require(newAddress != address(0), "Invalid address");

        nameRecords[name].resolvedAddress = newAddress;

        emit AddressUpdated(name, newAddress);
    }

    /**
     * @dev Update metadata for a name
     * @param name Name to update
     * @param metadata New metadata
     */
    function updateMetadata(string memory name, string memory metadata) 
        public 
        nameRegistered(name)
        onlyNameOwner(name)
    {
        nameRecords[name].metadata = metadata;

        emit MetadataUpdated(name, metadata);
    }

    /**
     * @dev Release a name (make it available for registration)
     * @param name Name to release
     */
    function releaseName(string memory name) 
        public 
        nameRegistered(name)
        onlyNameOwner(name)
    {
        NameRecord storage record = nameRecords[name];
        record.active = false;

        ownerStats[msg.sender].namesOwned--;

        // Clear primary name if it was the released name
        if (keccak256(bytes(primaryName[msg.sender])) == keccak256(bytes(name))) {
            delete primaryName[msg.sender];
        }

        emit NameReleased(name, msg.sender);
    }

    /**
     * @dev Set primary name for reverse lookup
     * @param name Name to set as primary
     */
    function setPrimaryName(string memory name) 
        public 
        nameRegistered(name)
        onlyNameOwner(name)
    {
        primaryName[msg.sender] = name;

        emit PrimaryNameSet(msg.sender, name);
    }

    /**
     * @dev Resolve a name to an address
     * @param name Name to resolve
     * @return Resolved address
     */
    function resolve(string memory name) public view nameRegistered(name) returns (address) {
        NameRecord memory record = nameRecords[name];
        require(record.active, "Name is not active");
        require(block.timestamp < record.expiryTime, "Name has expired");
        return record.resolvedAddress;
    }

    /**
     * @dev Reverse lookup - get primary name for an address
     * @param addr Address to lookup
     * @return Primary name
     */
    function reverseLookup(address addr) public view returns (string memory) {
        return primaryName[addr];
    }

    /**
     * @dev Get name record details
     * @param name Name to query
     * @return NameRecord details
     */
    function getNameRecord(string memory name) 
        public 
        view 
        nameRegistered(name)
        returns (NameRecord memory) 
    {
        return nameRecords[name];
    }

    /**
     * @dev Check if name is available for registration
     * @param name Name to check
     * @return true if available
     */
    function isNameAvailable(string memory name) public view returns (bool) {
        if (!nameExists[name]) {
            return true;
        }
        
        NameRecord memory record = nameRecords[name];
        return !record.active || block.timestamp >= record.expiryTime;
    }

    /**
     * @dev Check if name is registered
     * @param name Name to check
     * @return true if registered
     */
    function isNameRegistered(string memory name) public view returns (bool) {
        return nameExists[name];
    }

    /**
     * @dev Get names owned by an address
     * @param addr Owner address
     * @return Array of names
     */
    function getNamesByOwner(address addr) public view returns (string[] memory) {
        string[] memory names = ownerNames[addr];
        
        // Filter active names
        uint256 count = 0;
        for (uint256 i = 0; i < names.length; i++) {
            if (nameRecords[names[i]].active && nameRecords[names[i]].owner == addr) {
                count++;
            }
        }

        string[] memory result = new string[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < names.length; i++) {
            if (nameRecords[names[i]].active && nameRecords[names[i]].owner == addr) {
                result[index] = names[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get all registered names
     * @return Array of all names
     */
    function getAllNames() public view returns (string[] memory) {
        return allNames;
    }

    /**
     * @dev Get active names
     * @return Array of active names
     */
    function getActiveNames() public view returns (string[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allNames.length; i++) {
            NameRecord memory record = nameRecords[allNames[i]];
            if (record.active && block.timestamp < record.expiryTime) {
                count++;
            }
        }

        string[] memory result = new string[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allNames.length; i++) {
            NameRecord memory record = nameRecords[allNames[i]];
            if (record.active && block.timestamp < record.expiryTime) {
                result[index] = allNames[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get expired names
     * @return Array of expired names
     */
    function getExpiredNames() public view returns (string[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allNames.length; i++) {
            NameRecord memory record = nameRecords[allNames[i]];
            if (record.active && block.timestamp >= record.expiryTime) {
                count++;
            }
        }

        string[] memory result = new string[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allNames.length; i++) {
            NameRecord memory record = nameRecords[allNames[i]];
            if (record.active && block.timestamp >= record.expiryTime) {
                result[index] = allNames[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get owner statistics
     * @param addr Owner address
     * @return OwnerStats details
     */
    function getOwnerStats(address addr) public view returns (OwnerStats memory) {
        return ownerStats[addr];
    }

    /**
     * @dev Get time until name expiry
     * @param name Name to check
     * @return Seconds until expiry (0 if expired)
     */
    function getTimeUntilExpiry(string memory name) 
        public 
        view 
        nameRegistered(name)
        returns (uint256) 
    {
        NameRecord memory record = nameRecords[name];
        if (block.timestamp >= record.expiryTime) {
            return 0;
        }
        return record.expiryTime - block.timestamp;
    }

    /**
     * @dev Get total registered names count
     * @return Total names registered
     */
    function getTotalNamesRegistered() public view returns (uint256) {
        return totalNamesRegistered;
    }

    /**
     * @dev Get active names count
     * @return Number of active names
     */
    function getActiveNamesCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allNames.length; i++) {
            NameRecord memory record = nameRecords[allNames[i]];
            if (record.active && block.timestamp < record.expiryTime) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Update registration and renewal fees
     * @param newRegistrationFee New registration fee
     * @param newRenewalFee New renewal fee
     */
    function updateFees(uint256 newRegistrationFee, uint256 newRenewalFee) public onlyOwner {
        registrationFee = newRegistrationFee;
        renewalFee = newRenewalFee;

        emit FeesUpdated(newRegistrationFee, newRenewalFee);
    }

    /**
     * @dev Update registration period
     * @param newPeriod New registration period in seconds
     */
    function updateRegistrationPeriod(uint256 newPeriod) public onlyOwner {
        require(newPeriod > 0, "Period must be greater than 0");
        registrationPeriod = newPeriod;
    }

    /**
     * @dev Withdraw collected fees
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");

        payable(owner).transfer(amount);
    }

    /**
     * @dev Withdraw all collected fees
     */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);
    }

    /**
     * @dev Get contract balance
     * @return Contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
