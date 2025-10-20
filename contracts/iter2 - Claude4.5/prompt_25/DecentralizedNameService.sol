// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    struct NameRecord {
        address owner;
        address resolvedAddress;
        uint256 registrationDate;
        uint256 expiryDate;
        bool isActive;
    }
    
    mapping(string => NameRecord) public nameRecords;
    mapping(address => string[]) public ownerNames;
    mapping(string => bool) public nameExists;
    
    uint256 public registrationFee = 0.01 ether;
    uint256 public registrationPeriod = 365 days;
    uint256 public renewalFee = 0.005 ether;
    
    address public owner;
    
    event NameRegistered(string indexed name, address indexed owner, address resolvedAddress, uint256 expiryDate);
    event NameRenewed(string indexed name, address indexed owner, uint256 newExpiryDate);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event AddressUpdated(string indexed name, address oldAddress, address newAddress);
    event NameReleased(string indexed name, address indexed previousOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyNameOwner(string memory _name) {
        require(nameExists[_name], "Name does not exist");
        require(nameRecords[_name].owner == msg.sender, "Not the name owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function registerName(string memory _name, address _resolvedAddress) external payable {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_name).length <= 32, "Name too long");
        require(_resolvedAddress != address(0), "Resolved address cannot be zero");
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!nameExists[_name] || !nameRecords[_name].isActive || block.timestamp > nameRecords[_name].expiryDate, "Name already registered and active");
        
        // If name existed before, release it first
        if (nameExists[_name]) {
            _releaseName(_name);
        }
        
        uint256 expiryDate = block.timestamp + registrationPeriod;
        
        nameRecords[_name] = NameRecord({
            owner: msg.sender,
            resolvedAddress: _resolvedAddress,
            registrationDate: block.timestamp,
            expiryDate: expiryDate,
            isActive: true
        });
        
        nameExists[_name] = true;
        ownerNames[msg.sender].push(_name);
        
        emit NameRegistered(_name, msg.sender, _resolvedAddress, expiryDate);
        
        // Refund excess payment
        if (msg.value > registrationFee) {
            (bool success, ) = msg.sender.call{value: msg.value - registrationFee}("");
            require(success, "Refund failed");
        }
    }
    
    function renewName(string memory _name) external payable onlyNameOwner(_name) {
        require(msg.value >= renewalFee, "Insufficient renewal fee");
        
        NameRecord storage record = nameRecords[_name];
        
        // Extend from current expiry or from now, whichever is later
        uint256 baseTime = block.timestamp > record.expiryDate ? block.timestamp : record.expiryDate;
        record.expiryDate = baseTime + registrationPeriod;
        record.isActive = true;
        
        emit NameRenewed(_name, msg.sender, record.expiryDate);
        
        // Refund excess payment
        if (msg.value > renewalFee) {
            (bool success, ) = msg.sender.call{value: msg.value - renewalFee}("");
            require(success, "Refund failed");
        }
    }
    
    function updateAddress(string memory _name, address _newAddress) external onlyNameOwner(_name) {
        require(_newAddress != address(0), "New address cannot be zero");
        require(block.timestamp <= nameRecords[_name].expiryDate, "Name has expired");
        
        address oldAddress = nameRecords[_name].resolvedAddress;
        nameRecords[_name].resolvedAddress = _newAddress;
        
        emit AddressUpdated(_name, oldAddress, _newAddress);
    }
    
    function transferName(string memory _name, address _newOwner) external onlyNameOwner(_name) {
        require(_newOwner != address(0), "New owner cannot be zero");
        require(block.timestamp <= nameRecords[_name].expiryDate, "Name has expired");
        
        address previousOwner = nameRecords[_name].owner;
        nameRecords[_name].owner = _newOwner;
        
        // Remove from previous owner's list
        _removeNameFromOwner(previousOwner, _name);
        
        // Add to new owner's list
        ownerNames[_newOwner].push(_name);
        
        emit NameTransferred(_name, previousOwner, _newOwner);
    }
    
    function releaseName(string memory _name) external onlyNameOwner(_name) {
        _releaseName(_name);
    }
    
    function _releaseName(string memory _name) private {
        address previousOwner = nameRecords[_name].owner;
        
        nameRecords[_name].isActive = false;
        
        // Remove from owner's list
        _removeNameFromOwner(previousOwner, _name);
        
        emit NameReleased(_name, previousOwner);
    }
    
    function _removeNameFromOwner(address _owner, string memory _name) private {
        string[] storage names = ownerNames[_owner];
        
        for (uint256 i = 0; i < names.length; i++) {
            if (keccak256(bytes(names[i])) == keccak256(bytes(_name))) {
                names[i] = names[names.length - 1];
                names.pop();
                break;
            }
        }
    }
    
    function resolveName(string memory _name) external view returns (address) {
        require(nameExists[_name], "Name does not exist");
        require(nameRecords[_name].isActive, "Name is not active");
        require(block.timestamp <= nameRecords[_name].expiryDate, "Name has expired");
        
        return nameRecords[_name].resolvedAddress;
    }
    
    function getNameInfo(string memory _name) external view returns (
        address nameOwner,
        address resolvedAddress,
        uint256 registrationDate,
        uint256 expiryDate,
        bool isActive,
        bool isExpired
    ) {
        require(nameExists[_name], "Name does not exist");
        
        NameRecord memory record = nameRecords[_name];
        bool expired = block.timestamp > record.expiryDate;
        
        return (
            record.owner,
            record.resolvedAddress,
            record.registrationDate,
            record.expiryDate,
            record.isActive && !expired,
            expired
        );
    }
    
    function getOwnerNames(address _owner) external view returns (string[] memory) {
        return ownerNames[_owner];
    }
    
    function isNameAvailable(string memory _name) external view returns (bool) {
        if (!nameExists[_name]) {
            return true;
        }
        
        NameRecord memory record = nameRecords[_name];
        return !record.isActive || block.timestamp > record.expiryDate;
    }
    
    function updateRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
    }
    
    function updateRenewalFee(uint256 _newFee) external onlyOwner {
        renewalFee = _newFee;
    }
    
    function updateRegistrationPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "Period must be greater than 0");
        registrationPeriod = _newPeriod;
    }
    
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
