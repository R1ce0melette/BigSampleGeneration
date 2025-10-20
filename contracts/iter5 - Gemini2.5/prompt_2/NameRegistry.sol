// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NameRegistry
 * @dev A contract for registering, updating, and removing names associated with wallet addresses.
 */
contract NameRegistry {

    // Mapping from address to a registered name
    mapping(address => string) public addressToName;
    // Mapping from a name to the address that registered it
    mapping(string => address) public nameToAddress;

    /**
     * @dev Event emitted when a new name is registered.
     * @param user The address of the user.
     * @param name The name registered by the user.
     */
    event NameRegistered(address indexed user, string name);

    /**
     * @dev Event emitted when a name is updated.
     * @param user The address of the user.
     * @param oldName The previous name.
     * @param newName The new name.
     */
    event NameUpdated(address indexed user, string oldName, string newName);

    /**
     * @dev Event emitted when a name is removed.
     * @param user The address of the user.
     * @param name The name that was removed.
     */
    event NameRemoved(address indexed user, string name);

    /**
     * @dev Registers a new name for the caller's address.
     * - The name must not be empty.
     * - The name must not already be registered.
     * - The caller must not have a name registered already.
     * @param _name The name to register.
     */
    function registerName(string memory _name) public {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(nameToAddress[_name] == address(0), "Name is already taken.");
        require(bytes(addressToName[msg.sender]).length == 0, "You have already registered a name.");

        addressToName[msg.sender] = _name;
        nameToAddress[_name] = msg.sender;

        emit NameRegistered(msg.sender, _name);
    }

    /**
     * @dev Updates the registered name for the caller's address.
     * - The new name must not be empty.
     * - The new name must not already be registered.
     * - The caller must have a name registered.
     * @param _newName The new name to associate with the address.
     */
    function updateName(string memory _newName) public {
        require(bytes(_newName).length > 0, "New name cannot be empty.");
        require(nameToAddress[_newName] == address(0), "New name is already taken.");
        
        string memory oldName = addressToName[msg.sender];
        require(bytes(oldName).length > 0, "You do not have a name registered.");

        // Clean up old name mapping
        delete nameToAddress[oldName];

        // Set new name mapping
        addressToName[msg.sender] = _newName;
        nameToAddress[_newName] = msg.sender;

        emit NameUpdated(msg.sender, oldName, _newName);
    }

    /**
     * @dev Removes the registered name for the caller's address.
     * - The caller must have a name registered.
     */
    function removeName() public {
        string memory nameToRemove = addressToName[msg.sender];
        require(bytes(nameToRemove).length > 0, "You do not have a name registered.");

        delete addressToName[msg.sender];
        delete nameToAddress[nameToRemove];

        emit NameRemoved(msg.sender, nameToRemove);
    }

    /**
     * @dev Retrieves the name associated with a given address.
     * @param _address The address to query.
     * @return The name registered to the address.
     */
    function getName(address _address) public view returns (string memory) {
        return addressToName[_address];
    }

    /**
     * @dev Retrieves the address associated with a given name.
     * @param _name The name to query.
     * @return The address registered with the name.
     */
    function getAddress(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }
}
