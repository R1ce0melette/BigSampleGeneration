// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    struct NameRecord {
        address owner;
        address resolvedAddress;
        uint256 registrationDate;
        uint256 expirationDate;
        bool exists;
    }

    mapping(string => NameRecord) public nameRecords;
    mapping(address => string[]) public ownerNames;
    mapping(string => bool) public isNameTaken;

    uint256 public registrationFee;
    uint256 public registrationPeriod;
    address public serviceOwner;

    event NameRegistered(string indexed name, address indexed owner, address resolvedAddress, uint256 expirationDate);
    event NameRenewed(string indexed name, uint256 newExpirationDate);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event AddressUpdated(string indexed name, address newAddress);
    event NameReleased(string indexed name);

    modifier onlyServiceOwner() {
        require(msg.sender == serviceOwner, "Only service owner can perform this action");
        _;
    }

    modifier onlyNameOwner(string memory name) {
        require(nameRecords[name].exists, "Name does not exist");
        require(nameRecords[name].owner == msg.sender, "Not the name owner");
        _;
    }

    constructor(uint256 _registrationFee, uint256 _registrationPeriodInDays) {
        serviceOwner = msg.sender;
        registrationFee = _registrationFee;
        registrationPeriod = _registrationPeriodInDays * 1 days;
    }

    function registerName(string memory name, address resolvedAddress) external payable {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 50, "Name too long");
        require(resolvedAddress != address(0), "Invalid resolved address");
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(!isNameTaken[name] || isNameExpired(name), "Name already taken");

        // If name existed before and expired, clean it up
        if (nameRecords[name].exists && isNameExpired(name)) {
            _releaseName(name);
        }

        uint256 expirationDate = block.timestamp + registrationPeriod;

        nameRecords[name] = NameRecord({
            owner: msg.sender,
            resolvedAddress: resolvedAddress,
            registrationDate: block.timestamp,
            expirationDate: expirationDate,
            exists: true
        });

        isNameTaken[name] = true;
        ownerNames[msg.sender].push(name);

        emit NameRegistered(name, msg.sender, resolvedAddress, expirationDate);
    }

    function renewName(string memory name) external payable onlyNameOwner(name) {
        require(msg.value >= registrationFee, "Insufficient renewal fee");
        require(!isNameExpired(name), "Name has expired, please re-register");

        nameRecords[name].expirationDate += registrationPeriod;

        emit NameRenewed(name, nameRecords[name].expirationDate);
    }

    function updateResolvedAddress(string memory name, address newAddress) external onlyNameOwner(name) {
        require(newAddress != address(0), "Invalid address");
        require(!isNameExpired(name), "Name has expired");

        nameRecords[name].resolvedAddress = newAddress;

        emit AddressUpdated(name, newAddress);
    }

    function transferName(string memory name, address newOwner) external onlyNameOwner(name) {
        require(newOwner != address(0), "Invalid new owner address");
        require(!isNameExpired(name), "Name has expired");

        address previousOwner = nameRecords[name].owner;
        nameRecords[name].owner = newOwner;

        // Remove from previous owner's list
        _removeNameFromOwner(previousOwner, name);

        // Add to new owner's list
        ownerNames[newOwner].push(name);

        emit NameTransferred(name, previousOwner, newOwner);
    }

    function releaseName(string memory name) external onlyNameOwner(name) {
        _releaseName(name);
        emit NameReleased(name);
    }

    function _releaseName(string memory name) private {
        address owner = nameRecords[name].owner;
        
        delete nameRecords[name];
        delete isNameTaken[name];
        
        _removeNameFromOwner(owner, name);
    }

    function _removeNameFromOwner(address owner, string memory name) private {
        string[] storage names = ownerNames[owner];
        
        for (uint256 i = 0; i < names.length; i++) {
            if (keccak256(bytes(names[i])) == keccak256(bytes(name))) {
                names[i] = names[names.length - 1];
                names.pop();
                break;
            }
        }
    }

    function resolveName(string memory name) external view returns (address) {
        require(nameRecords[name].exists, "Name does not exist");
        require(!isNameExpired(name), "Name has expired");
        return nameRecords[name].resolvedAddress;
    }

    function getNameRecord(string memory name) external view returns (
        address owner,
        address resolvedAddress,
        uint256 registrationDate,
        uint256 expirationDate,
        bool exists
    ) {
        NameRecord memory record = nameRecords[name];
        return (record.owner, record.resolvedAddress, record.registrationDate, record.expirationDate, record.exists);
    }

    function isNameExpired(string memory name) public view returns (bool) {
        if (!nameRecords[name].exists) {
            return false;
        }
        return block.timestamp > nameRecords[name].expirationDate;
    }

    function isNameAvailable(string memory name) external view returns (bool) {
        return !isNameTaken[name] || isNameExpired(name);
    }

    function getOwnerNames(address owner) external view returns (string[] memory) {
        return ownerNames[owner];
    }

    function getTimeUntilExpiration(string memory name) external view returns (uint256) {
        require(nameRecords[name].exists, "Name does not exist");
        
        if (isNameExpired(name)) {
            return 0;
        }
        
        return nameRecords[name].expirationDate - block.timestamp;
    }

    function updateRegistrationFee(uint256 newFee) external onlyServiceOwner {
        registrationFee = newFee;
    }

    function updateRegistrationPeriod(uint256 newPeriodInDays) external onlyServiceOwner {
        require(newPeriodInDays > 0, "Period must be greater than 0");
        registrationPeriod = newPeriodInDays * 1 days;
    }

    function withdrawFees() external onlyServiceOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");

        (bool success, ) = serviceOwner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
