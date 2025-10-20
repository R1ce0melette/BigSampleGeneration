// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NameRegistry
 * @dev A contract that allows users to register, update, and remove names associated with their wallet addresses
 */
contract NameRegistry {
    // Mapping from address to name
    mapping(address => string) public addressToName;
    
    // Mapping from name to address (to prevent duplicate names)
    mapping(string => address) public nameToAddress;
    
    // Events
    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string oldName, string newName);
    event NameRemoved(address indexed user, string name);
    
    /**
     * @dev Registers a name for the caller's address
     * @param name The name to register
     * Requirements:
     * - Name must not be empty
     * - Name must not already be taken by another address
     * - Caller must not already have a name registered
     */
    function registerName(string memory name) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(addressToName[msg.sender]).length == 0, "Address already has a name registered");
        require(nameToAddress[name] == address(0), "Name already taken");
        
        addressToName[msg.sender] = name;
        nameToAddress[name] = msg.sender;
        
        emit NameRegistered(msg.sender, name);
    }
    
    /**
     * @dev Updates the name for the caller's address
     * @param newName The new name to set
     * Requirements:
     * - Caller must have a name registered
     * - New name must not be empty
     * - New name must not already be taken by another address
     */
    function updateName(string memory newName) external {
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
        require(bytes(newName).length > 0, "New name cannot be empty");
        require(nameToAddress[newName] == address(0), "Name already taken");
        
        string memory oldName = addressToName[msg.sender];
        
        // Remove old name mapping
        delete nameToAddress[oldName];
        
        // Set new name mappings
        addressToName[msg.sender] = newName;
        nameToAddress[newName] = msg.sender;
        
        emit NameUpdated(msg.sender, oldName, newName);
    }
    
    /**
     * @dev Removes the name registration for the caller's address
     * Requirements:
     * - Caller must have a name registered
     */
    function removeName() external {
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
        
        string memory name = addressToName[msg.sender];
        
        // Remove both mappings
        delete nameToAddress[name];
        delete addressToName[msg.sender];
        
        emit NameRemoved(msg.sender, name);
    }
    
    /**
     * @dev Returns the name associated with the caller's address
     * @return The name of the caller
     */
    function getMyName() external view returns (string memory) {
        return addressToName[msg.sender];
    }
    
    /**
     * @dev Returns the name associated with a specific address
     * @param user The address to query
     * @return The name associated with the address
     */
    function getNameOf(address user) external view returns (string memory) {
        return addressToName[user];
    }
    
    /**
     * @dev Returns the address associated with a specific name
     * @param name The name to query
     * @return The address associated with the name
     */
    function getAddressOf(string memory name) external view returns (address) {
        return nameToAddress[name];
    }
    
    /**
     * @dev Checks if a name is available for registration
     * @param name The name to check
     * @return True if the name is available, false otherwise
     */
    function isNameAvailable(string memory name) external view returns (bool) {
        return nameToAddress[name] == address(0);
    }
}
