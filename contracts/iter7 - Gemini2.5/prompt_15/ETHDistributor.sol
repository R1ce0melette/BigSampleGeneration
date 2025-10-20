// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ETHDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients.
 */
contract ETHDistributor {
    // The address of the contract owner.
    address public owner;

    /**
     * @dev Emitted when ETH is distributed to recipients.
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
        require(msg.sender == owner, "ETHDistributor: Caller is not the owner.");
        _;
    }

    /**
     * @dev Sets the contract owner to the deployer's address.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Distributes the sent ETH evenly among a list of recipients.
     * Any remainder from the division is sent back to the owner.
     * @param _recipients An array of addresses to receive the ETH.
     */
    function distribute(address payable[] memory _recipients) public payable onlyOwner {
        uint256 recipientCount = _recipients.length;
        require(recipientCount > 0, "ETHDistributor: No recipients provided.");
        require(msg.value > 0, "ETHDistributor: No ETH sent for distribution.");

        uint256 amountPerRecipient = msg.value / recipientCount;
        uint256 remainder = msg.value % recipientCount;

        for (uint256 i = 0; i < recipientCount; i++) {
            require(_recipients[i] != address(0), "ETHDistributor: Cannot send to the zero address.");
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "ETHDistributor: Failed to send ETH to a recipient.");
        }

        if (remainder > 0) {
            (bool success, ) = payable(owner).call{value: remainder}("");
            require(success, "ETHDistributor: Failed to send remainder to the owner.");
        }

        emit ETHDistributed(msg.sender, msg.value - remainder, recipientCount);
    }

    /**
     * @dev Allows the owner to withdraw any ETH accidentally sent to the contract.
     */
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(owner).call{value: balance}("");
            require(success, "ETHDistributor: Failed to withdraw contract balance.");
        }
    }
}
