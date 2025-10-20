// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedNameService {
    // Mapping from a name (string) to an address
    mapping(string => address) public nameToAddress;
    // Mapping from an address to a name (string) to ensure one name per address
    mapping(address => string) public addressToName;

    uint256 public registrationFee = 0.01 ether;

    event NameRegistered(string name, address indexed owner);
    event NameTransferred(string name, address indexed from, address indexed to);
    event FeeUpdated(uint256 newFee);

    modifier nameIsAvailable(string memory _name) {
        require(nameToAddress[_name] == address(0), "Name is already taken.");
        _;
    }

    modifier senderHasNoName() {
        require(bytes(addressToName[msg.sender]).length == 0, "Address already has a name registered.");
        _;
    }

    /**
     * @dev Registers a new name and maps it to the sender's address.
     * @param _name The name to register.
     */
    function registerName(string memory _name) public payable nameIsAvailable(_name) senderHasNoName {
        require(msg.value >= registrationFee, "Insufficient registration fee.");
        require(bytes(_name).length > 0, "Name cannot be empty.");

        nameToAddress[_name] = msg.sender;
        addressToName[msg.sender] = _name;

        emit NameRegistered(_name, msg.sender);
    }

    /**
     * @dev Transfers a registered name to a new address.
     * @param _name The name to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferName(string memory _name, address _newOwner) public {
        require(nameToAddress[_name] == msg.sender, "Only the owner can transfer the name.");
        require(_newOwner != address(0), "New owner address cannot be zero.");
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
     * @param _name The name to resolve.
     * @return The address associated with the name.
     */
    function resolveName(string memory _name) public view returns (address) {
        return nameToAddress[_name];
    }

    /**
     * @dev Allows the contract owner to update the registration fee.
     * @param _newFee The new registration fee.
     */
    function setRegistrationFee(uint256 _newFee) public {
        // In a real contract, this should be restricted (e.g., onlyOwner)
        registrationFee = _newFee;
        emit FeeUpdated(_newFee);
    }
}
