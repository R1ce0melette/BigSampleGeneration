// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NameRegistry
 * @dev A contract that allows users to register, update, and remove names associated with their wallet addresses
 */
contract NameRegistry {
    // Mapping from address to registered name
    mapping(address => string) public addressToName;
    
    // Mapping from name to address (to prevent duplicate names)
    mapping(string => address) public nameToAddress;
    
    // Events
    event NameRegistered(address indexed user, string name);
    event NameUpdated(address indexed user, string oldName, string newName);
    event NameRemoved(address indexed user, string name);
    
    /**
     * @dev Register a name for the caller's address
     * @param name The name to register
     * Requirements:
     * - Name must not be empty
     * - Caller must not already have a registered name
     * - Name must not already be taken by another address
     */
    function registerName(string memory name) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(addressToName[msg.sender]).length == 0, "Address already has a registered name");
        require(nameToAddress[name] == address(0), "Name already taken");
        
        addressToName[msg.sender] = name;
        nameToAddress[name] = msg.sender;
        
        emit NameRegistered(msg.sender, name);
    }
    
    /**
     * @dev Update the caller's registered name
     * @param newName The new name to register
     * Requirements:
     * - Caller must have a registered name
     * - New name must not be empty
     * - New name must not already be taken by another address
     */
    function updateName(string memory newName) external {
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
        require(bytes(newName).length > 0, "Name cannot be empty");
        require(nameToAddress[newName] == address(0), "Name already taken");
        
        string memory oldName = addressToName[msg.sender];
        
        // Remove old name mapping
        delete nameToAddress[oldName];
        
        // Set new name mapping
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
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
        
        string memory name = addressToName[msg.sender];
        
        // Remove mappings
        delete nameToAddress[name];
        delete addressToName[msg.sender];
        
        emit NameRemoved(msg.sender, name);
    }
    
    /**
     * @dev Get the name registered to an address
     * @param user The address to query
     * @return The name registered to the address
     */
    function getNameByAddress(address user) external view returns (string memory) {
        return addressToName[user];
    }
    
    /**
     * @dev Get the address that registered a name
     * @param name The name to query
     * @return The address that registered the name
     */
    function getAddressByName(string memory name) external view returns (address) {
        return nameToAddress[name];
    }
    
    /**
     * @dev Get the caller's registered name
     * @return The name registered to the caller
     */
    function getMyName() external view returns (string memory) {
        return addressToName[msg.sender];
    }
    
    /**
     * @dev Check if a name is available
     * @param name The name to check
     * @return True if the name is available, false otherwise
     */
    function isNameAvailable(string memory name) external view returns (bool) {
        return nameToAddress[name] == address(0);
    }
}
