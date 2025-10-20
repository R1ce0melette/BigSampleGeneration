// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedNameService
 * @dev A contract for a basic decentralized name service, allowing users to
 * register, update, and resolve names to wallet addresses.
 */
contract DecentralizedNameService {
    // Mapping from a name (string) to an address
    mapping(string => address) private nameToAddress;
    // Mapping from an address to a name (string)
    mapping(address => string) private addressToName;

    /**
     * @dev Emitted when a new name is registered.
     * @param name The registered name.
     * @param owner The address of the name's owner.
     */
    event NameRegistered(string name, address indexed owner);

    /**
     * @dev Emitted when a name's associated address is updated.
     * @param name The name that was updated.
     * @param newAddress The new address associated with the name.
     */
    event NameUpdated(string name, address indexed newAddress);

    /**
     * @dev Emitted when a name is transferred to a new owner.
     * @param name The name that was transferred.
     * @param newOwner The address of the new owner.
     */
    event NameTransferred(string name, address indexed newOwner);

    /**
     * @dev Emitted when a name is released (deleted).
     * @param name The name that was released.
     */
    event NameReleased(string name);

    /**
     * @dev Registers a new name and associates it with the sender's address.
     * The name must not already be registered.
     * @param _name The name to register.
     */
    function register(string memory _name) public {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(nameToAddress[_name] == address(0), "Name is already registered.");
        // Optional: prevent an address from owning multiple names
        require(bytes(addressToName[msg.sender]).length == 0, "Address already has a name registered.");

        nameToAddress[_name] = msg.sender;
        addressToName[msg.sender] = _name;

        emit NameRegistered(_name, msg.sender);
    }

    /**
     * @dev Resolves a name to its associated wallet address.
     * @param _name The name to resolve.
     * @return The address associated with the name.
     */
    function resolve(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }

    /**
     * @dev Updates the address associated with a name owned by the sender.
     * This is less common as names usually point to their owner's address.
     * A more practical function is `transferName`.
     * @param _name The name to update.
     * @param _newAddress The new address to associate with the name.
     */
    function updateAddress(string memory _name, address _newAddress) public {
        require(nameToAddress[_name] == msg.sender, "Only the owner can update the address.");
        require(_newAddress != address(0), "New address cannot be the zero address.");

        nameToAddress[_name] = _newAddress;
        emit NameUpdated(_name, _newAddress);
    }

    /**
     * @dev Transfers ownership of a name to a new address.
     * @param _name The name to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferName(string memory _name, address _newOwner) public {
        require(nameToAddress[_name] == msg.sender, "Only the owner can transfer the name.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        require(nameToAddress[_name] != _newOwner, "New owner is the same as the current owner.");
        // Ensure the new owner doesn't already have a name
        require(bytes(addressToName[_newOwner]).length == 0, "New owner already has a name registered.");

        // Update mappings
        address oldOwner = msg.sender;
        nameToAddress[_name] = _newOwner;
        addressToName[_newOwner] = _name;
        delete addressToName[oldOwner];

        emit NameTransferred(_name, _newOwner);
    }

    /**
     * @dev Releases (deletes) a name, making it available for others to register.
     * Only the owner of the name can release it.
     * @param _name The name to release.
     */
    function release(string memory _name) public {
        require(nameToAddress[_name] == msg.sender, "Only the owner can release the name.");

        address owner = nameToAddress[_name];
        delete nameToAddress[_name];
        delete addressToName[owner];

        emit NameReleased(_name);
    }
}
