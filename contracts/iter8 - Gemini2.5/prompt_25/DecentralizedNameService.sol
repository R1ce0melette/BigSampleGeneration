// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedNameService
 * @dev A basic decentralized name service where users can register, update, and resolve names.
 * Names are mapped to wallet addresses.
 */
contract DecentralizedNameService {
    address public owner;
    uint256 public registrationFee;

    struct NameRecord {
        address owner;
        address targetAddress;
        uint256 expires;
    }

    mapping(string => NameRecord) public nameRecords;
    mapping(string => bool) public isRegistered;

    event NameRegistered(string name, address indexed owner, address indexed targetAddress, uint256 expires);
    event NameTransferred(string name, address indexed newOwner);
    event AddressUpdated(string name, address indexed newTargetAddress);
    event FeeUpdated(uint256 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyNameOwner(string memory _name) {
        require(nameRecords[_name].owner == msg.sender, "You are not the owner of this name.");
        _;
    }

    /**
     * @dev Sets the initial registration fee.
     * @param _initialFee The cost to register a name for one year.
     */
    constructor(uint256 _initialFee) {
        owner = msg.sender;
        registrationFee = _initialFee;
    }

    /**
     * @dev Registers a new name for one year.
     * @param _name The name to register.
     * @param _targetAddress The address this name will resolve to.
     */
    function register(string memory _name, address _targetAddress) external payable {
        require(!isRegistered[_name] || nameRecords[_name].expires < block.timestamp, "Name is already taken or has not expired.");
        require(msg.value == registrationFee, "Incorrect registration fee.");
        require(bytes(_name).length > 0, "Name cannot be empty.");

        uint256 expiryTime = block.timestamp + 365 days;
        nameRecords[_name] = NameRecord({
            owner: msg.sender,
            targetAddress: _targetAddress,
            expires: expiryTime
        });
        isRegistered[_name] = true;

        emit NameRegistered(_name, msg.sender, _targetAddress, expiryTime);
    }

    /**
     * @dev Transfers ownership of a registered name.
     * @param _name The name to transfer.
     * @param _newOwner The new owner of the name.
     */
    function transferName(string memory _name, address _newOwner) external onlyNameOwner(_name) {
        require(nameRecords[_name].expires >= block.timestamp, "Name has expired.");
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        
        nameRecords[_name].owner = _newOwner;
        emit NameTransferred(_name, _newOwner);
    }

    /**
     * @dev Updates the target address a name resolves to.
     * @param _name The name to update.
     * @param _newTargetAddress The new address for the name to resolve to.
     */
    function updateAddress(string memory _name, address _newTargetAddress) external onlyNameOwner(_name) {
        require(nameRecords[_name].expires >= block.timestamp, "Name has expired.");
        
        nameRecords[_name].targetAddress = _newTargetAddress;
        emit AddressUpdated(_name, _newTargetAddress);
    }

    /**
     * @dev Resolves a name to its target address.
     * @param _name The name to resolve.
     * @return The target address.
     */
    function resolve(string memory _name) external view returns (address) {
        require(isRegistered[_name] && nameRecords[_name].expires >= block.timestamp, "Name not registered or has expired.");
        return nameRecords[_name].targetAddress;
    }

    /**
     * @dev Allows the contract owner to update the registration fee.
     * @param _newFee The new registration fee.
     */
    function setRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    /**
     * @dev Allows the contract owner to withdraw collected fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw.");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed.");
    }
}
