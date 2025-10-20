// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NameRegistry
 * @dev A contract that allows users to register, update, and remove names associated with their wallet addresses
 */
contract NameRegistry {
    // Mapping from address to registered name
    mapping(address => string) public addressToName;
    
    // Mapping from name to address (to check uniqueness)
    mapping(string => address) public nameToAddress;
    
    // Events
    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string oldName, string newName);
    event NameRemoved(address indexed user, string name);
    
    /**
     * @dev Register a name for the caller's address
     * @param name The name to register
     * Requirements:
     * - Name cannot be empty
     * - Caller must not already have a registered name
     * - Name must not be already taken by another address
     */
    function registerName(string memory name) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(addressToName[msg.sender]).length == 0, "Address already has a registered name");
        require(nameToAddress[name] == address(0), "Name is already taken");
        
        addressToName[msg.sender] = name;
        nameToAddress[name] = msg.sender;
        
        emit NameRegistered(msg.sender, name);
    }
    
    /**
     * @dev Update the caller's registered name
     * @param newName The new name to register
     * Requirements:
     * - New name cannot be empty
     * - Caller must have a registered name
     * - New name must not be already taken by another address
     */
    function updateName(string memory newName) external {
        require(bytes(newName).length > 0, "Name cannot be empty");
        string memory oldName = addressToName[msg.sender];
        require(bytes(oldName).length > 0, "No name registered for this address");
        require(nameToAddress[newName] == address(0), "Name is already taken");
        
        // Remove old name mapping
        delete nameToAddress[oldName];
        
        // Set new name mappings
        addressToName[msg.sender] = newName;
        nameToAddress[newName] = msg.sender;
        
        emit NameUpdated(msg.sender, oldName, newName);
    }
    
    /**
     * @dev Remove the caller's registered name
     * Requirements:
     * - Caller must have a registered name
     */
    function removeName() external {
        string memory name = addressToName[msg.sender];
        require(bytes(name).length > 0, "No name registered for this address");
        
        delete nameToAddress[name];
        delete addressToName[msg.sender];
        
        emit NameRemoved(msg.sender, name);
    }
    
    /**
     * @dev Get the name registered to a specific address
     * @param user The address to query
     * @return The registered name, or empty string if none
     */
    function getName(address user) external view returns (string memory) {
        return addressToName[user];
    }
    
    /**
     * @dev Get the address associated with a specific name
     * @param name The name to query
     * @return The address associated with the name, or zero address if none
     */
    function getAddress(string memory name) external view returns (address) {
        return nameToAddress[name];
    }
    
    /**
     * @dev Check if a name is available
     * @param name The name to check
     * @return True if the name is available, false otherwise
     */
    function isNameAvailable(string memory name) external view returns (bool) {
        return nameToAddress[name] == address(0);
    }
    
    /**
     * @dev Get the caller's registered name
     * @return The registered name, or empty string if none
     */
    function getMyName() external view returns (string memory) {
        return addressToName[msg.sender];
    }
}
