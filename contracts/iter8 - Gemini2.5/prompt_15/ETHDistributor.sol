// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ETHDistributor
 * @dev A contract that allows the owner to distribute ETH evenly among a list of recipients.
 */
contract ETHDistributor {
    address public owner;

    event Distributed(address indexed recipient, uint256 amount);
    event RemainderSent(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Distributes the sent ETH evenly among a list of recipients.
     * Any remainder from the division is sent back to the owner.
     * @param _recipients A list of addresses to receive ETH.
     */
    function distribute(address payable[] memory _recipients) external payable onlyOwner {
        uint256 recipientCount = _recipients.length;
        require(recipientCount > 0, "Recipient list cannot be empty.");
        require(msg.value > 0, "Must send ETH to distribute.");

        uint256 amountPerRecipient = msg.value / recipientCount;
        require(amountPerRecipient > 0, "Amount per recipient must be greater than zero.");

        for (uint256 i = 0; i < recipientCount; i++) {
            (bool success, ) = _recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed.");
            emit Distributed(_recipients[i], amountPerRecipient);
        }

        uint256 remainder = msg.value % recipientCount;
        if (remainder > 0) {
            (bool success, ) = payable(owner).call{value: remainder}("");
            require(success, "Remainder transfer failed.");
            emit RemainderSent(owner, remainder);
        }
    }

    /**
     * @dev Allows the owner to withdraw any ETH accidentally sent to the contract.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed.");
    }
}
