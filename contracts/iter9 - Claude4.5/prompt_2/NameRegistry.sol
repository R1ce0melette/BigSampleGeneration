// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
     * @dev Register a name for the caller's address
     * @param name The name to register
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
     * @dev Update the name associated with the caller's address
     * @param newName The new name to set
     */
    function updateName(string memory newName) external {
        require(bytes(newName).length > 0, "Name cannot be empty");
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
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
     * @dev Remove the name associated with the caller's address
     */
    function removeName() external {
        require(bytes(addressToName[msg.sender]).length > 0, "No name registered for this address");
        
        string memory name = addressToName[msg.sender];
        
        delete nameToAddress[name];
        delete addressToName[msg.sender];
        
        emit NameRemoved(msg.sender, name);
    }
    
    /**
     * @dev Get the name associated with an address
     * @param user The address to query
     * @return The name associated with the address
     */
    function getNameByAddress(address user) external view returns (string memory) {
        return addressToName[user];
    }
    
    /**
     * @dev Get the address associated with a name
     * @param name The name to query
     * @return The address associated with the name
     */
    function getAddressByName(string memory name) external view returns (address) {
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
}
