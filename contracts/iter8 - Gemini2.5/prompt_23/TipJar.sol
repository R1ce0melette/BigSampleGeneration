// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TipJar
 * @dev A simple contract that allows users to send ETH tips to a designated creator.
 * The contract tracks the total amount of tips received.
 */
contract TipJar {
    address payable public creator;
    uint256 public totalTips;

    event Tipped(address indexed tipper, uint256 amount, string message);
    event Withdrawn(address indexed creator, uint256 amount);

    /**
     * @dev Sets the creator of the tip jar.
     * @param _creator The address of the person who will receive the tips.
     */
    constructor(address payable _creator) {
        require(_creator != address(0), "Creator address cannot be the zero address.");
        creator = _creator;
    }

    /**
     * @dev Allows anyone to send a tip to the creator.
     * @param _message A message to accompany the tip.
     */
    function tip(string memory _message) external payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        
        totalTips += msg.value;
        
        emit Tipped(msg.sender, msg.value, _message);
    }

    /**
     * @dev Allows the creator to withdraw the entire balance of the contract.
     */
    function withdraw() external {
        require(msg.sender == creator, "Only the creator can withdraw funds.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");

        (bool success, ) = creator.call{value: balance}("");
        require(success, "Withdrawal failed.");

        emit Withdrawn(creator, balance);
    }

    /**
     * @dev Fallback function to receive plain ETH transfers as tips.
     */
    receive() external payable {
        tip("");
    }
}
