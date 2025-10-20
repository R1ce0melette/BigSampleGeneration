// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ETHDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients.
 */
contract ETHDistributor {
    // Address of the contract owner who can initiate distributions.
    address public owner;

    /**
     * @dev Event emitted when ETH is distributed to recipients.
     * @param distributor The address of the owner who initiated the distribution.
     * @param totalAmount The total amount of ETH distributed.
     * @param recipientCount The number of recipients who received ETH.
     */
    event ETHDistributed(
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
     * @dev Distributes the sent ETH evenly among a list of recipient addresses.
     * - Only the owner can call this function.
     * - The number of recipients must be greater than zero.
     * - The total ETH sent must be perfectly divisible by the number of recipients to avoid dust.
     * @param _recipients An array of addresses to receive the ETH.
     */
    function distribute(address payable[] memory _recipients) public payable onlyOwner {
        uint256 recipientCount = _recipients.length;
        require(recipientCount > 0, "Recipient list cannot be empty.");
        require(msg.value > 0, "Distribution amount must be greater than zero.");
        require(msg.value % recipientCount == 0, "Amount must be evenly divisible by the number of recipients.");

        uint256 amountPerRecipient = msg.value / recipientCount;

        for (uint256 i = 0; i < recipientCount; i++) {
            require(_recipients[i] != address(0), "Cannot send to the zero address.");
            (bool sent, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(sent, "Failed to send ETH to a recipient.");
        }

        emit ETHDistributed(msg.sender, msg.value, recipientCount);
    }

    /**
     * @dev Allows the owner to withdraw any ETH accidentally sent to the contract.
     */
    function withdrawRemainingETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No remaining ETH to withdraw.");

        (bool sent, ) = payable(owner).call{value: balance}("");
        require(sent, "Failed to withdraw remaining ETH.");
    }

    /**
     * @dev Changes the owner of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        owner = _newOwner;
    }
}
