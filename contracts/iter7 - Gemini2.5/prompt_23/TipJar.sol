// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TipJar
 * @dev A simple contract that allows users to send ETH tips to a creator.
 * The contract tracks the total tips received and allows the creator to withdraw them.
 */
contract TipJar {
    // The address of the creator who will receive the tips.
    address public immutable creator;

    // The total amount of ETH tipped to the creator.
    uint256 public totalTips;

    /**
     * @dev Emitted when a tip is sent.
     * @param tipper The address of the user who sent the tip.
     * @param amount The amount of ETH tipped.
     */
    event Tipped(address indexed tipper, uint256 amount);

    /**
     * @dev Emitted when the creator withdraws the tips.
     * @param amount The amount of ETH withdrawn.
     */
    event Withdrawn(uint256 amount);

    /**
     * @dev Sets the creator's address when the contract is deployed.
     * The creator is the one who deploys the contract.
     */
    constructor() {
        creator = msg.sender;
    }

    /**
     * @dev Allows anyone to send a tip to the creator.
     */
    function tip() public payable {
        require(msg.value > 0, "TipJar: Tip amount must be greater than zero.");
        totalTips += msg.value;
        emit Tipped(msg.sender, msg.value);
    }

    /**
     * @dev Allows the creator to withdraw the entire balance of the tip jar.
     */
    function withdraw() public {
        require(msg.sender == creator, "TipJar: Only the creator can withdraw.");
        uint256 balance = address(this).balance;
        require(balance > 0, "TipJar: No tips to withdraw.");

        (bool success, ) = payable(creator).call{value: balance}("");
        require(success, "TipJar: Withdrawal failed.");

        emit Withdrawn(balance);
    }
}
