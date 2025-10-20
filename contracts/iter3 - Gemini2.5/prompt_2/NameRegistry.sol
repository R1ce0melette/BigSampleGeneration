// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NameRegistry
 * @dev A contract that lets users register their names and associate them with their wallet address.
 * It also allows for updating and removing names.
 */
contract NameRegistry {
    // Mapping from an address to a name
    mapping(address => string) private _addressToName;
    // Mapping from a name to an address
    mapping(string => address) private _nameToAddress;

    /**
     * @dev Event emitted when a name is successfully registered.
     * @param owner The address that registered the name.
     * @param name The name that was registered.
     */
    event NameRegistered(address indexed owner, string name);

    /**
     * @dev Event emitted when a name is successfully updated.
     * @param owner The address that updated the name.
     * @param oldName The previous name.
     * @param newName The new name.
     */
    event NameUpdated(address indexed owner, string oldName, string newName);

    /**
     * @dev Event emitted when a name is successfully removed.
     * @param owner The address that removed the name.
     * @param name The name that was removed.
     */
    event NameRemoved(address indexed owner, string name);

    /**
     * @dev Registers a name for the sender's address.
     * - The name must not be empty.
     * - The name must not already be in use.
     * - The sender must not already have a name registered.
     * @param name The name to register.
     */
    function registerName(string memory name) public {
        require(bytes(name).length > 0, "Name cannot be empty.");
        require(_nameToAddress[name] == address(0), "Name is already taken.");
        require(bytes(_addressToName[msg.sender]).length == 0, "Address already has a name registered.");

        _addressToName[msg.sender] = name;
        _nameToAddress[name] = msg.sender;

        emit NameRegistered(msg.sender, name);
    }

    /**
     * @dev Updates the name associated with the sender's address.
     * - The new name must not be empty.
     * - The new name must not already be in use.
     * - The sender must have a name registered.
     * @param newName The new name to associate with the sender's address.
     */
    function updateName(string memory newName) public {
        require(bytes(_addressToName[msg.sender]).length > 0, "No name registered for this address.");
        require(bytes(newName).length > 0, "New name cannot be empty.");
        require(_nameToAddress[newName] == address(0), "New name is already taken.");

        string memory oldName = _addressToName[msg.sender];
        delete _nameToAddress[oldName];

        _addressToName[msg.sender] = newName;
        _nameToAddress[newName] = msg.sender;

        emit NameUpdated(msg.sender, oldName, newName);
    }

    /**
     * @dev Removes the name associated with the sender's address.
     * - The sender must have a name registered.
     */
    function removeName() public {
        string memory name = _addressToName[msg.sender];
        require(bytes(name).length > 0, "No name registered for this address.");

        delete _addressToName[msg.sender];
        delete _nameToAddress[name];

        emit NameRemoved(msg.sender, name);
    }

    /**
     * @dev Retrieves the name associated with a given address.
     * @param owner The address to query.
     * @return The name associated with the address.
     */
    function getName(address owner) public view returns (string memory) {
        return _addressToName[owner];
    }

    /**
     * @dev Retrieves the address associated with a given name.
     * @param name The name to query.
     * @return The address associated with the name.
     */
    function getAddress(string memory name) public view returns (address) {
        return _nameToAddress[name];
    }
}
