// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NameRegistry
 * @dev A contract that allows users to register, update, and remove a name
 * associated with their wallet address.
 */
contract NameRegistry {
    // Mapping from an address to the name it is associated with.
    mapping(address => string) private _names;

    /**
     * @dev Emitted when a name is successfully set (registered or updated).
     * @param user The address of the user.
     * @param name The name that was set.
     */
    event NameSet(address indexed user, string name);

    /**
     * @dev Emitted when a name is successfully removed.
     * @param user The address of the user whose name was removed.
     */
    event NameRemoved(address indexed user);

    /**
     * @dev Registers or updates the name for the `msg.sender`.
     * @param name The name to associate with the caller's address. Must not be empty.
     */
    function setName(string memory name) public {
        require(bytes(name).length > 0, "Name cannot be empty.");
        _names[msg.sender] = name;
        emit NameSet(msg.sender, name);
    }

    /**
     * @dev Removes the name associated with the `msg.sender`.
     * Reverts if the user does not have a name registered.
     */
    function removeName() public {
        require(bytes(_names[msg.sender]).length > 0, "No name to remove.");
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
