// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Distributor {
    address public owner;

    event Distributed(address[] recipients, uint256 amountPerRecipient);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Distributes the contract's balance evenly among a list of recipients.
     * @param _recipients An array of addresses to receive ETH.
     */
    function distribute(address payable[] memory _recipients) public onlyOwner {
        require(_recipients.length > 0, "Recipient list cannot be empty.");
        
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "Contract has no balance to distribute.");
        
        uint256 amountPerRecipient = totalBalance / _recipients.length;
        require(amountPerRecipient > 0, "Distribution amount per recipient is zero.");

        for (uint i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(amountPerRecipient);
        }

        emit Distributed(_recipients, amountPerRecipient);
    }

    /**
     * @dev Allows the owner to deposit ETH into the contract.
     */
    function deposit() public payable onlyOwner {
        // Function body is empty as the payable modifier handles the ETH transfer.
    }

    /**
     * @dev Retrieves the current balance of the contract.
     * @return The balance in wei.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
