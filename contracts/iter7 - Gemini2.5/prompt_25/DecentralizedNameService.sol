// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedNameService
 * @dev A basic decentralized name service where users can register, update, and resolve names to wallet addresses.
 */
contract DecentralizedNameService {
    // Mapping from a name (string) to the address it resolves to.
    mapping(string => address) private nameToAddress;
    
    // Mapping from an address to the name it owns. This ensures each address can only own one name.
    mapping(address => string) private addressToName;

    /**
     * @dev Emitted when a new name is registered.
     * @param name The registered name.
     * @param owner The address that owns the name.
     */
    event NameRegistered(string name, address indexed owner);

    /**
     * @dev Emitted when a name is transferred to a new owner.
     * @param name The transferred name.
     * @param oldOwner The previous owner of the name.
     * @param newOwner The new owner of the name.
     */
    event NameTransferred(string name, address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Registers a new name and associates it with the caller's address.
     * @param _name The name to register. Must not be already taken.
     */
    function registerName(string memory _name) public {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(nameToAddress[_name] == address(0), "Name is already taken.");
        require(bytes(addressToName[msg.sender]).length == 0, "You already own a name.");

        nameToAddress[_name] = msg.sender;
        addressToName[msg.sender] = _name;

        emit NameRegistered(_name, msg.sender);
    }

    /**
     * @dev Resolves a name to its associated wallet address.
     * @param _name The name to resolve.
     * @return The address associated with the name. Returns the zero address if the name is not registered.
     */
    function resolveName(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }

    /**
     * @dev Retrieves the name owned by a specific address.
     * @param _owner The address to query.
     * @return The name owned by the address. Returns an empty string if the address does not own a name.
     */
    function getNameByAddress(address _owner) public view returns (string memory) {
        return addressToName[_owner];
    }

    /**
     * @dev Transfers ownership of a name to a new address.
     * Only the current owner of the name can initiate a transfer.
     * @param _name The name to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferName(string memory _name, address _newOwner) public {
        require(nameToAddress[_name] == msg.sender, "You are not the owner of this name.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        require(bytes(addressToName[_newOwner]).length == 0, "New owner already owns a name.");

        address oldOwner = msg.sender;

        // Update mappings for the new owner
        nameToAddress[_name] = _newOwner;
        addressToName[_newOwner] = _name;

        // Clear the mapping for the old owner
        delete addressToName[oldOwner];

        emit NameTransferred(_name, oldOwner, _newOwner);
    }
}
