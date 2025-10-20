// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Airdrop is Ownable {

    event Distributed(address indexed recipient, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Distributes the contract's entire ETH balance evenly among a list of recipients.
     *      The function is payable to allow the owner to send ETH to the contract in the same transaction.
     * @param _recipients An array of addresses to receive the ETH.
     */
    function distribute(address payable[] memory _recipients) public payable onlyOwner {
        uint256 totalRecipients = _recipients.length;
        require(totalRecipients > 0, "Recipient list cannot be empty.");
        
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "Contract has no ETH to distribute.");

        uint256 amountPerRecipient = totalBalance / totalRecipients;
        require(amountPerRecipient > 0, "Distribution amount per recipient is zero.");

        for (uint i = 0; i < totalRecipients; i++) {
            address payable recipient = _recipients[i];
            // It's good practice to check if the recipient address is not zero.
            if (recipient != address(0)) {
                recipient.transfer(amountPerRecipient);
                emit Distributed(recipient, amountPerRecipient);
            }
        }
    }

    /**
     * @dev Fallback function to receive ETH.
     */
    receive() external payable {}
}
