// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public registrar;

    struct Property {
        uint256 id;
        string propertyAddress;
        string description;
        address owner;
        uint256 registrationDate;
        bool exists;
    }

    struct TransferHistory {
        address from;
        address to;
        uint256 timestamp;
    }

    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(uint256 => TransferHistory[]) public transferHistory;
    mapping(address => uint256[]) public ownerProperties;

    event PropertyRegistered(uint256 indexed propertyId, string propertyAddress, address indexed owner, uint256 timestamp);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 timestamp);
    event PropertyUpdated(uint256 indexed propertyId, string newDescription);

    modifier onlyRegistrar() {
        require(msg.sender == registrar, "Only registrar can perform this action");
        _;
    }

    modifier propertyExists(uint256 propertyId) {
        require(propertyId > 0 && propertyId <= propertyCount, "Property does not exist");
        require(properties[propertyId].exists, "Property does not exist");
        _;
    }

    constructor() {
        registrar = msg.sender;
    }

    function registerProperty(
        string memory propertyAddress,
        string memory description,
        address owner
    ) external onlyRegistrar {
        require(bytes(propertyAddress).length > 0, "Property address cannot be empty");
        require(owner != address(0), "Invalid owner address");

        propertyCount++;

        properties[propertyCount] = Property({
            id: propertyCount,
            propertyAddress: propertyAddress,
            description: description,
            owner: owner,
            registrationDate: block.timestamp,
            exists: true
        });

        ownerProperties[owner].push(propertyCount);

        emit PropertyRegistered(propertyCount, propertyAddress, owner, block.timestamp);
    }

    function transferProperty(uint256 propertyId, address newOwner) external onlyRegistrar propertyExists(propertyId) {
        require(newOwner != address(0), "Invalid new owner address");
        Property storage property = properties[propertyId];
        require(property.owner != newOwner, "New owner is already the current owner");

        address previousOwner = property.owner;

        // Remove property from previous owner's list
        _removePropertyFromOwner(previousOwner, propertyId);

        // Add property to new owner's list
        ownerProperties[newOwner].push(propertyId);

        // Record transfer history
        transferHistory[propertyId].push(TransferHistory({
            from: previousOwner,
            to: newOwner,
            timestamp: block.timestamp
        }));

        // Update property owner
        property.owner = newOwner;

        emit PropertyTransferred(propertyId, previousOwner, newOwner, block.timestamp);
    }

    function updatePropertyDescription(uint256 propertyId, string memory newDescription) external onlyRegistrar propertyExists(propertyId) {
        require(bytes(newDescription).length > 0, "Description cannot be empty");

        properties[propertyId].description = newDescription;

        emit PropertyUpdated(propertyId, newDescription);
    }

    function getProperty(uint256 propertyId) external view propertyExists(propertyId) returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registrationDate
    ) {
        Property memory property = properties[propertyId];
        return (
            property.id,
            property.propertyAddress,
            property.description,
            property.owner,
            property.registrationDate
        );
    }

    function verifyOwnership(uint256 propertyId, address owner) external view propertyExists(propertyId) returns (bool) {
        return properties[propertyId].owner == owner;
    }

    function getOwnerProperties(address owner) external view returns (uint256[] memory) {
        return ownerProperties[owner];
    }

    function getTransferHistory(uint256 propertyId) external view propertyExists(propertyId) returns (TransferHistory[] memory) {
        return transferHistory[propertyId];
    }

    function _removePropertyFromOwner(address owner, uint256 propertyId) private {
        uint256[] storage properties = ownerProperties[owner];
        
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i] == propertyId) {
                // Move the last element to the position of the element to remove
                properties[i] = properties[properties.length - 1];
                properties.pop();
                break;
            }
        }
    }

    function changeRegistrar(address newRegistrar) external onlyRegistrar {
        require(newRegistrar != address(0), "Invalid registrar address");
        registrar = newRegistrar;
    }
}
