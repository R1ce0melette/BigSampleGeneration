// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NameRegistry
 * @dev A contract that allows users to register, update, and remove a name associated with their wallet address.
 */
contract NameRegistry {
    // Mapping from address to a user-defined name
    mapping(address => string) private _names;

    // Event to be emitted when a name is set (registered or updated)
    event NameSet(address indexed user, string name);

    // Event to be emitted when a name is removed
    event NameRemoved(address indexed user);

    /**
     * @dev Registers or updates the name for the caller's address.
     * @param name The name to associate with the address. Must not be empty.
     */
    function setName(string memory name) public {
        require(bytes(name).length > 0, "NameRegistry: Name cannot be empty.");
        _names[msg.sender] = name;
        emit NameSet(msg.sender, name);
    }

    /**
     * @dev Removes the name associated with the caller's address.
     * Reverts if the user does not have a name registered.
     */
    function removeName() public {
        require(bytes(_names[msg.sender]).length > 0, "NameRegistry: No name to remove.");
        delete _names[msg.sender];
        emit NameRemoved(msg.sender);
    }

    /**
     * @dev Retrieves the name associated with a given address.
     * @param user The address to query.
     * @return The name associated with the address, or an empty string if not set.
     */
    function getName(address user) public view returns (string memory) {
        return _names[user];
    }
}
