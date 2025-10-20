// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NameRegistry
 * @dev Contract that lets users register names and associate them with wallet addresses
 */
contract NameRegistry {
    // State variables
    mapping(address => string) private addressToName;
    mapping(string => address) private nameToAddress;
    mapping(address => bool) private hasRegistered;
    mapping(string => bool) private nameTaken;
    
    address[] private registeredUsers;
    string[] private registeredNames;

    // Events
    event NameRegistered(address indexed user, string name, uint256 timestamp);
    event NameUpdated(address indexed user, string oldName, string newName, uint256 timestamp);
    event NameRemoved(address indexed user, string name, uint256 timestamp);

    /**
     * @dev Register a name for the caller
     * @param name Name to register
     */
    function registerName(string memory name) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 32, "Name too long");
        require(!hasRegistered[msg.sender], "Address already has a registered name");
        require(!nameTaken[name], "Name already taken");

        addressToName[msg.sender] = name;
        nameToAddress[name] = msg.sender;
        hasRegistered[msg.sender] = true;
        nameTaken[name] = true;
        
        registeredUsers.push(msg.sender);
        registeredNames.push(name);

        emit NameRegistered(msg.sender, name, block.timestamp);
    }

    /**
     * @dev Update the registered name
     * @param newName New name to register
     */
    function updateName(string memory newName) public {
        require(hasRegistered[msg.sender], "No name registered for this address");
        require(bytes(newName).length > 0, "Name cannot be empty");
        require(bytes(newName).length <= 32, "Name too long");
        require(!nameTaken[newName], "Name already taken");

        string memory oldName = addressToName[msg.sender];
        
        // Remove old name mappings
        delete nameToAddress[oldName];
        delete nameTaken[oldName];

        // Set new name mappings
        addressToName[msg.sender] = newName;
        nameToAddress[newName] = msg.sender;
        nameTaken[newName] = true;

        emit NameUpdated(msg.sender, oldName, newName, block.timestamp);
    }

    /**
     * @dev Remove the registered name
     */
    function removeName() public {
        require(hasRegistered[msg.sender], "No name registered for this address");

        string memory name = addressToName[msg.sender];

        delete addressToName[msg.sender];
        delete nameToAddress[name];
        delete hasRegistered[msg.sender];
        delete nameTaken[name];

        emit NameRemoved(msg.sender, name, block.timestamp);
    }

    /**
     * @dev Get name associated with an address
     * @param user User address
     * @return Name string
     */
    function getNameByAddress(address user) public view returns (string memory) {
        require(hasRegistered[user], "No name registered for this address");
        return addressToName[user];
    }

    /**
     * @dev Get address associated with a name
     * @param name Name to look up
     * @return User address
     */
    function getAddressByName(string memory name) public view returns (address) {
        address user = nameToAddress[name];
        require(user != address(0), "Name not registered");
        return user;
    }

    /**
     * @dev Get caller's registered name
     * @return Name string
     */
    function getMyName() public view returns (string memory) {
        require(hasRegistered[msg.sender], "No name registered for this address");
        return addressToName[msg.sender];
    }

    /**
     * @dev Check if an address has a registered name
     * @param user User address
     * @return true if registered
     */
    function isNameRegistered(address user) public view returns (bool) {
        return hasRegistered[user];
    }

    /**
     * @dev Check if a name is taken
     * @param name Name to check
     * @return true if taken
     */
    function isNameTaken(string memory name) public view returns (bool) {
        return nameTaken[name];
    }

    /**
     * @dev Get all registered users
     * @return Array of user addresses
     */
    function getAllRegisteredUsers() public view returns (address[] memory) {
        return registeredUsers;
    }

    /**
     * @dev Get all registered names
     * @return Array of names
     */
    function getAllRegisteredNames() public view returns (string[] memory) {
        return registeredNames;
    }

    /**
     * @dev Get total number of registered users
     * @return Total count
     */
    function getTotalRegistered() public view returns (uint256) {
        return registeredUsers.length;
    }

    /**
     * @dev Check if caller has registered a name
     * @return true if registered
     */
    function hasMyNameRegistered() public view returns (bool) {
        return hasRegistered[msg.sender];
    }
}
