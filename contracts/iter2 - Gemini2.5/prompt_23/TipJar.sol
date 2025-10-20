// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TipJar is Ownable {
    address payable public creator;
    uint256 public totalTipsReceived;

    event Tipped(address indexed tipper, uint256 amount);
    event Withdrawn(address indexed creator, uint256 amount);

    /**
     * @dev The constructor sets the creator of the tip jar.
     * @param _creator The address of the creator who will receive the tips.
     */
    constructor(address payable _creator) Ownable(msg.sender) {
        require(_creator != address(0), "Creator address cannot be zero.");
        creator = _creator;
    }

    /**
     * @dev Allows anyone to send a tip in ETH to the creator.
     */
    function tip() public payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        
        totalTipsReceived += msg.value;
        emit Tipped(msg.sender, msg.value);
    }

    /**
     * @dev Allows the creator to withdraw the collected tips.
     */
    function withdrawTips() public {
        require(msg.sender == creator, "Only the creator can withdraw tips.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw.");

        emit Withdrawn(creator, balance);
        creator.transfer(balance);
    }

    /**
     * @dev Allows the contract owner (deployer) to change the creator address.
     * @param _newCreator The address of the new creator.
     */
    function changeCreator(address payable _newCreator) public onlyOwner {
        require(_newCreator != address(0), "New creator address cannot be zero.");
        creator = _newCreator;
    }
}
