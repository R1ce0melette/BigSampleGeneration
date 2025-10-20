// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BasicNameService
 * @dev A simple decentralized name service mapping names to wallet addresses.
 */
contract BasicNameService {

    mapping(string => address) public nameToAddress;
    mapping(address => string) public addressToName;
    address public owner;

    event NameRegistered(string name, address indexed owner);
    event NameTransferred(string name, address indexed from, address indexed to);

    modifier onlyOwnerOfName(string memory _name) {
        require(nameToAddress[_name] == msg.sender, "You do not own this name.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Registers a new name and maps it to the sender's address.
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
     * @dev Transfers ownership of a name to a new address.
     */
    function transferName(string memory _name, address _newOwner) public onlyOwnerOfName(_name) {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        require(bytes(addressToName[_newOwner]).length == 0, "New owner already has a name registered.");

        address oldOwner = msg.sender;
        
        // Update mappings
        nameToAddress[_name] = _newOwner;
        addressToName[_newOwner] = _name;
        delete addressToName[oldOwner];
        
        emit NameTransferred(_name, oldOwner, _newOwner);
    }

    /**
     * @dev Resolves a name to its corresponding address.
     */
    function resolveName(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }
}
