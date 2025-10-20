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
        bool isRegistered;
    }
    
    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties;
    mapping(string => uint256) public addressToPropertyId;
    
    event PropertyRegistered(uint256 indexed propertyId, string propertyAddress, address indexed owner);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to);
    event PropertyDetailsUpdated(uint256 indexed propertyId, string newDescription);
    
    modifier onlyRegistrar() {
        require(msg.sender == registrar, "Only registrar can call this function");
        _;
    }
    
    modifier onlyPropertyOwner(uint256 _propertyId) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist");
        require(properties[_propertyId].owner == msg.sender, "Only property owner can call this function");
        _;
    }
    
    constructor() {
        registrar = msg.sender;
    }
    
    function registerProperty(
        string memory _propertyAddress,
        string memory _description,
        address _owner
    ) external onlyRegistrar {
        require(bytes(_propertyAddress).length > 0, "Property address cannot be empty");
        require(_owner != address(0), "Invalid owner address");
        require(addressToPropertyId[_propertyAddress] == 0, "Property already registered");
        
        propertyCount++;
        
        properties[propertyCount] = Property({
            id: propertyCount,
            propertyAddress: _propertyAddress,
            description: _description,
            owner: _owner,
            registrationDate: block.timestamp,
            isRegistered: true
        });
        
        ownerProperties[_owner].push(propertyCount);
        addressToPropertyId[_propertyAddress] = propertyCount;
        
        emit PropertyRegistered(propertyCount, _propertyAddress, _owner);
    }
    
    function transferProperty(uint256 _propertyId, address _newOwner) external {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist");
        require(_newOwner != address(0), "Invalid new owner address");
        
        Property storage property = properties[_propertyId];
        
        require(property.isRegistered, "Property is not registered");
        require(msg.sender == property.owner || msg.sender == registrar, "Not authorized to transfer");
        require(_newOwner != property.owner, "New owner is the same as current owner");
        
        address previousOwner = property.owner;
        property.owner = _newOwner;
        
        ownerProperties[_newOwner].push(_propertyId);
        
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner);
    }
    
    function updatePropertyDetails(uint256 _propertyId, string memory _newDescription) 
        external 
        onlyRegistrar 
    {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist");
        require(bytes(_newDescription).length > 0, "Description cannot be empty");
        
        Property storage property = properties[_propertyId];
        require(property.isRegistered, "Property is not registered");
        
        property.description = _newDescription;
        
        emit PropertyDetailsUpdated(_propertyId, _newDescription);
    }
    
    function verifyOwnership(uint256 _propertyId, address _owner) external view returns (bool) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist");
        
        Property memory property = properties[_propertyId];
        
        return property.isRegistered && property.owner == _owner;
    }
    
    function getProperty(uint256 _propertyId) external view returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registrationDate,
        bool isRegistered
    ) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Property does not exist");
        
        Property memory property = properties[_propertyId];
        
        return (
            property.id,
            property.propertyAddress,
            property.description,
            property.owner,
            property.registrationDate,
            property.isRegistered
        );
    }
    
    function getPropertyByAddress(string memory _propertyAddress) external view returns (
        uint256 id,
        string memory propertyAddress,
        string memory description,
        address owner,
        uint256 registrationDate,
        bool isRegistered
    ) {
        uint256 propertyId = addressToPropertyId[_propertyAddress];
        require(propertyId > 0, "Property not found");
        
        Property memory property = properties[propertyId];
        
        return (
            property.id,
            property.propertyAddress,
            property.description,
            property.owner,
            property.registrationDate,
            property.isRegistered
        );
    }
    
    function getOwnerProperties(address _owner) external view returns (uint256[] memory) {
        return ownerProperties[_owner];
    }
    
    function getOwnerPropertyCount(address _owner) external view returns (uint256) {
        return ownerProperties[_owner].length;
    }
    
    function changeRegistrar(address _newRegistrar) external onlyRegistrar {
        require(_newRegistrar != address(0), "Invalid registrar address");
        registrar = _newRegistrar;
    }
}
