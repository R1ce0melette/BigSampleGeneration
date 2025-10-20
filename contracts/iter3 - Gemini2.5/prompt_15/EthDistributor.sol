// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EthDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients.
 */
contract EthDistributor {
    address public owner;

    /**
     * @dev Emitted when ETH is distributed to recipients.
     * @param distributor The address of the owner who initiated the distribution.
     * @param totalAmount The total amount of ETH distributed.
     * @param recipientCount The number of recipients who received ETH.
     */
    event EthDistributed(
        address indexed distributor,
        uint256 totalAmount,
        uint256 recipientCount
    );

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the contract owner upon deployment.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Distributes the sent ETH evenly among a list of recipients.
     * The function must be called with a value (ETH) to be distributed.
     * @param _recipients An array of addresses to receive the ETH.
     */
    function distribute(address payable[] memory _recipients) public payable onlyOwner {
        uint256 recipientCount = _recipients.length;
        require(recipientCount > 0, "Recipient list cannot be empty.");
        require(msg.value > 0, "Distribution amount must be greater than zero.");

        uint256 amountPerRecipient = msg.value / recipientCount;
        require(amountPerRecipient > 0, "Amount per recipient must be greater than zero.");

        for (uint256 i = 0; i < recipientCount; i++) {
            require(_recipients[i] != address(0), "Recipient address cannot be the zero address.");
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            // It's generally better to not halt the entire distribution if one transfer fails,
            // but for simplicity in this contract, we require all to succeed.
            // A more advanced implementation might log failures and continue.
            require(success, "ETH transfer to a recipient failed.");
        }

        // If there's any remainder due to division, it stays in the contract.
        // The owner can withdraw it later.
        emit EthDistributed(msg.sender, msg.value, recipientCount);
    }

    /**
     * @dev Allows the owner to withdraw any ETH remaining in the contract.
     * This is useful for recovering any remainder from distributions.
     */
    function withdrawRemainingBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev Returns the current balance of the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the owner to transfer ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        owner = newOwner;
    }

    // It's good practice to have a receive function to accept ETH directly.
    receive() external payable {}
}
