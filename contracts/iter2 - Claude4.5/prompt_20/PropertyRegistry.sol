// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    address public registrar;
    
    struct Property {
        uint256 propertyId;
        string propertyAddress;
        string description;
        address owner;
        uint256 registrationDate;
        bool isRegistered;
    }
    
    struct TransferRecord {
        address from;
        address to;
        uint256 timestamp;
    }
    
    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(uint256 => TransferRecord[]) public transferHistory;
    mapping(address => uint256[]) public ownerProperties;
    mapping(string => uint256) public addressToPropertyId;
    
    event PropertyRegistered(uint256 indexed propertyId, string propertyAddress, address indexed owner, uint256 timestamp);
    event PropertyTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 timestamp);
    event PropertyUpdated(uint256 indexed propertyId, string newDescription);
    event RegistrarTransferred(address indexed previousRegistrar, address indexed newRegistrar);
    
    modifier onlyRegistrar() {
        require(msg.sender == registrar, "Only registrar can call this function");
        _;
    }
    
    modifier propertyExists(uint256 _propertyId) {
        require(_propertyId > 0 && _propertyId <= propertyCount, "Invalid property ID");
        require(properties[_propertyId].isRegistered, "Property not registered");
        _;
    }
    
    constructor() {
        registrar = msg.sender;
    }
    
    function registerProperty(
        string memory _propertyAddress,
        string memory _description,
        address _owner
    ) external onlyRegistrar returns (uint256) {
        require(bytes(_propertyAddress).length > 0, "Property address cannot be empty");
        require(_owner != address(0), "Owner address cannot be zero");
        require(addressToPropertyId[_propertyAddress] == 0, "Property already registered");
        
        propertyCount++;
        
        properties[propertyCount] = Property({
            propertyId: propertyCount,
            propertyAddress: _propertyAddress,
            description: _description,
            owner: _owner,
            registrationDate: block.timestamp,
            isRegistered: true
        });
        
        addressToPropertyId[_propertyAddress] = propertyCount;
        ownerProperties[_owner].push(propertyCount);
        
        emit PropertyRegistered(propertyCount, _propertyAddress, _owner, block.timestamp);
        
        return propertyCount;
    }
    
    function transferProperty(uint256 _propertyId, address _newOwner) external 
        onlyRegistrar 
        propertyExists(_propertyId) 
    {
        require(_newOwner != address(0), "New owner address cannot be zero");
        
        Property storage property = properties[_propertyId];
        address previousOwner = property.owner;
        
        require(previousOwner != _newOwner, "New owner is the same as current owner");
        
        // Remove from previous owner's list
        _removePropertyFromOwner(previousOwner, _propertyId);
        
        // Update property owner
        property.owner = _newOwner;
        
        // Add to new owner's list
        ownerProperties[_newOwner].push(_propertyId);
        
        // Record transfer
        transferHistory[_propertyId].push(TransferRecord({
            from: previousOwner,
            to: _newOwner,
            timestamp: block.timestamp
        }));
        
        emit PropertyTransferred(_propertyId, previousOwner, _newOwner, block.timestamp);
    }
    
    function updatePropertyDescription(uint256 _propertyId, string memory _newDescription) external 
        onlyRegistrar 
        propertyExists(_propertyId) 
    {
        require(bytes(_newDescription).length > 0, "Description cannot be empty");
        
        properties[_propertyId].description = _newDescription;
        
        emit PropertyUpdated(_propertyId, _newDescription);
    }
    
    function verifyOwnership(uint256 _propertyId, address _claimedOwner) external view 
        propertyExists(_propertyId) 
        returns (bool) 
    {
        return properties[_propertyId].owner == _claimedOwner;
    }
    
    function getProperty(uint256 _propertyId) external view 
        propertyExists(_propertyId) 
        returns (
            string memory propertyAddress,
            string memory description,
            address owner,
            uint256 registrationDate
        ) 
    {
        Property memory property = properties[_propertyId];
        
        return (
            property.propertyAddress,
            property.description,
            property.owner,
            property.registrationDate
        );
    }
    
    function getPropertyByAddress(string memory _propertyAddress) external view returns (
        uint256 propertyId,
        string memory description,
        address owner,
        uint256 registrationDate
    ) {
        uint256 propId = addressToPropertyId[_propertyAddress];
        require(propId > 0, "Property not found");
        
        Property memory property = properties[propId];
        
        return (
            property.propertyId,
            property.description,
            property.owner,
            property.registrationDate
        );
    }
    
    function getOwnerProperties(address _owner) external view returns (uint256[] memory) {
        return ownerProperties[_owner];
    }
    
    function getTransferHistory(uint256 _propertyId) external view 
        propertyExists(_propertyId) 
        returns (TransferRecord[] memory) 
    {
        return transferHistory[_propertyId];
    }
    
    function getTransferCount(uint256 _propertyId) external view 
        propertyExists(_propertyId) 
        returns (uint256) 
    {
        return transferHistory[_propertyId].length;
    }
    
    function transferRegistrar(address _newRegistrar) external onlyRegistrar {
        require(_newRegistrar != address(0), "New registrar cannot be zero address");
        require(_newRegistrar != registrar, "New registrar is the same as current");
        
        address previousRegistrar = registrar;
        registrar = _newRegistrar;
        
        emit RegistrarTransferred(previousRegistrar, _newRegistrar);
    }
    
    function _removePropertyFromOwner(address _owner, uint256 _propertyId) private {
        uint256[] storage properties = ownerProperties[_owner];
        
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i] == _propertyId) {
                properties[i] = properties[properties.length - 1];
                properties.pop();
                break;
            }
        }
    }
}
