// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TipJar
 * @dev A contract for a simple tip jar where users can send ETH to a creator.
 */
contract TipJar {
    address payable public creator;
    uint256 public totalTips;

    event Tipped(address indexed tipper, uint256 amount, string message);

    /**
     * @dev Sets the creator's address upon deployment.
     * @param _creator The address of the creator who will receive the tips.
     */
    constructor(address payable _creator) {
        require(_creator != address(0), "Creator address cannot be the zero address.");
        creator = _creator;
    }

    /**
     * @dev Allows anyone to send a tip to the creator.
     * @param _message A message to accompany the tip.
     */
    function tip(string memory _message) public payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        
        totalTips += msg.value;
        
        (bool sent, ) = creator.call{value: msg.value}("");
        require(sent, "Failed to send tip to the creator.");
        
        emit Tipped(msg.sender, msg.value, _message);
    }

    /**
     * @dev Changes the creator address.
     * @param _newCreator The new address to receive tips.
     */
    function changeCreator(address payable _newCreator) public {
        require(msg.sender == creator, "Only the current creator can change the address.");
        require(_newCreator != address(0), "New creator address cannot be the zero address.");
        creator = _newCreator;
    }
}
