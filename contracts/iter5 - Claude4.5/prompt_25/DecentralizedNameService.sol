// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    uint256 public constant RENEWAL_FEE = 0.005 ether;
    uint256 public constant REGISTRATION_PERIOD = 365 days;
    
    address public owner;
    
    struct NameRecord {
        address owner;
        uint256 expiryTime;
        string resolvedAddress;
        bool isActive;
    }
    
    mapping(string => NameRecord) public nameRecords;
    mapping(address => string[]) public ownerNames;
    mapping(string => bool) public nameExists;
    
    event NameRegistered(string indexed name, address indexed owner, uint256 expiryTime);
    event NameRenewed(string indexed name, uint256 newExpiryTime);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event AddressUpdated(string indexed name, string newAddress);
    event NameReleased(string indexed name);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier onlyNameOwner(string memory _name) {
        require(nameRecords[_name].owner == msg.sender, "Only name owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function registerName(string memory _name, string memory _resolvedAddress) external payable {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_name).length <= 32, "Name too long");
        require(msg.value >= REGISTRATION_FEE, "Insufficient registration fee");
        require(!nameExists[_name] || !isNameActive(_name), "Name is already registered");
        
        nameRecords[_name] = NameRecord({
            owner: msg.sender,
            expiryTime: block.timestamp + REGISTRATION_PERIOD,
            resolvedAddress: _resolvedAddress,
            isActive: true
        });
        
        nameExists[_name] = true;
        ownerNames[msg.sender].push(_name);
        
        emit NameRegistered(_name, msg.sender, block.timestamp + REGISTRATION_PERIOD);
    }
    
    function renewName(string memory _name) external payable onlyNameOwner(_name) {
        require(msg.value >= RENEWAL_FEE, "Insufficient renewal fee");
        require(nameExists[_name], "Name does not exist");
        
        NameRecord storage record = nameRecords[_name];
        
        if (record.expiryTime < block.timestamp) {
            record.expiryTime = block.timestamp + REGISTRATION_PERIOD;
        } else {
            record.expiryTime += REGISTRATION_PERIOD;
        }
        
        record.isActive = true;
        
        emit NameRenewed(_name, record.expiryTime);
    }
    
    function transferName(string memory _name, address _newOwner) external onlyNameOwner(_name) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(isNameActive(_name), "Name is expired");
        
        NameRecord storage record = nameRecords[_name];
        address previousOwner = record.owner;
        
        record.owner = _newOwner;
        ownerNames[_newOwner].push(_name);
        
        emit NameTransferred(_name, previousOwner, _newOwner);
    }
    
    function updateAddress(string memory _name, string memory _newAddress) external onlyNameOwner(_name) {
        require(isNameActive(_name), "Name is expired");
        
        nameRecords[_name].resolvedAddress = _newAddress;
        
        emit AddressUpdated(_name, _newAddress);
    }
    
    function releaseName(string memory _name) external onlyNameOwner(_name) {
        nameRecords[_name].isActive = false;
        
        emit NameReleased(_name);
    }
    
    function resolveName(string memory _name) external view returns (string memory) {
        require(nameExists[_name], "Name does not exist");
        require(isNameActive(_name), "Name is expired");
        
        return nameRecords[_name].resolvedAddress;
    }
    
    function getNameOwner(string memory _name) external view returns (address) {
        require(nameExists[_name], "Name does not exist");
        require(isNameActive(_name), "Name is expired");
        
        return nameRecords[_name].owner;
    }
    
    function getNameInfo(string memory _name) external view returns (
        address nameOwner,
        uint256 expiryTime,
        string memory resolvedAddress,
        bool isActive
    ) {
        require(nameExists[_name], "Name does not exist");
        
        NameRecord memory record = nameRecords[_name];
        
        return (
            record.owner,
            record.expiryTime,
            record.resolvedAddress,
            record.isActive && block.timestamp < record.expiryTime
        );
    }
    
    function isNameActive(string memory _name) public view returns (bool) {
        if (!nameExists[_name]) {
            return false;
        }
        
        NameRecord memory record = nameRecords[_name];
        return record.isActive && block.timestamp < record.expiryTime;
    }
    
    function isNameAvailable(string memory _name) external view returns (bool) {
        return !nameExists[_name] || !isNameActive(_name);
    }
    
    function getOwnerNames(address _owner) external view returns (string[] memory) {
        return ownerNames[_owner];
    }
    
    function timeUntilExpiry(string memory _name) external view returns (uint256) {
        require(nameExists[_name], "Name does not exist");
        
        NameRecord memory record = nameRecords[_name];
        
        if (block.timestamp >= record.expiryTime) {
            return 0;
        }
        
        return record.expiryTime - block.timestamp;
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
