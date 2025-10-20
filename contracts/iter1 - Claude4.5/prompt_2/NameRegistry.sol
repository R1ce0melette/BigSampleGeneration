// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameRegistry {
    // Mapping from address to name
    mapping(address => string) private addressToName;
    
    // Mapping from name to address (for uniqueness check)
    mapping(string => address) private nameToAddress;
    
    // Array to keep track of registered addresses
    address[] private registeredAddresses;
    
    // Events
    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string oldName, string newName);
    event NameRemoved(address indexed user, string name);
    
    // Error messages
    error NameAlreadyTaken(string name);
    error NoNameRegistered();
    error EmptyName();
    
    /**
     * @dev Register a name for the caller's address
     * @param _name The name to register
     */
    function registerName(string calldata _name) external {
        if (bytes(_name).length == 0) {
            revert EmptyName();
        }
        
        // Check if name is already taken
        if (nameToAddress[_name] != address(0)) {
            revert NameAlreadyTaken(_name);
        }
        
        // If user already has a name, remove the old mapping
        string memory oldName = addressToName[msg.sender];
        if (bytes(oldName).length > 0) {
            delete nameToAddress[oldName];
        } else {
            // If this is a new registration, add to the array
            registeredAddresses.push(msg.sender);
        }
        
        // Set new mappings
        addressToName[msg.sender] = _name;
        nameToAddress[_name] = msg.sender;
        
        if (bytes(oldName).length > 0) {
            emit NameUpdated(msg.sender, oldName, _name);
        } else {
            emit NameRegistered(msg.sender, _name);
        }
    }
    
    /**
     * @dev Update the name for the caller's address
     * @param _newName The new name to set
     */
    function updateName(string calldata _newName) external {
        if (bytes(_newName).length == 0) {
            revert EmptyName();
        }
        
        string memory oldName = addressToName[msg.sender];
        if (bytes(oldName).length == 0) {
            revert NoNameRegistered();
        }
        
        // Check if new name is already taken by someone else
        if (nameToAddress[_newName] != address(0) && nameToAddress[_newName] != msg.sender) {
            revert NameAlreadyTaken(_newName);
        }
        
        // Remove old name mapping
        delete nameToAddress[oldName];
        
        // Set new mappings
        addressToName[msg.sender] = _newName;
        nameToAddress[_newName] = msg.sender;
        
        emit NameUpdated(msg.sender, oldName, _newName);
    }
    
    /**
     * @dev Remove the name for the caller's address
     */
    function removeName() external {
        string memory name = addressToName[msg.sender];
        if (bytes(name).length == 0) {
            revert NoNameRegistered();
        }
        
        // Remove mappings
        delete addressToName[msg.sender];
        delete nameToAddress[name];
        
        // Remove from registered addresses array
        for (uint i = 0; i < registeredAddresses.length; i++) {
            if (registeredAddresses[i] == msg.sender) {
                registeredAddresses[i] = registeredAddresses[registeredAddresses.length - 1];
                registeredAddresses.pop();
                break;
            }
        }
        
        emit NameRemoved(msg.sender, name);
    }
    
    /**
     * @dev Get the name registered to an address
     * @param _address The address to query
     * @return The name registered to the address
     */
    function getName(address _address) external view returns (string memory) {
        return addressToName[_address];
    }
    
    /**
     * @dev Get the address that registered a specific name
     * @param _name The name to query
     * @return The address that registered the name
     */
    function getAddress(string calldata _name) external view returns (address) {
        return nameToAddress[_name];
    }
    
    /**
     * @dev Check if a name is available
     * @param _name The name to check
     * @return True if the name is available, false otherwise
     */
    function isNameAvailable(string calldata _name) external view returns (bool) {
        return nameToAddress[_name] == address(0);
    }
    
    /**
     * @dev Get all registered addresses
     * @return Array of addresses that have registered names
     */
    function getRegisteredAddresses() external view returns (address[] memory) {
        return registeredAddresses;
    }
    
    /**
     * @dev Get the total number of registered names
     * @return The count of registered names
     */
    function getRegisteredCount() external view returns (uint256) {
        return registeredAddresses.length;
    }
}