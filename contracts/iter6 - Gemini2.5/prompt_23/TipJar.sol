// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public creator;
    uint256 public totalTips;

    event Tipped(address indexed tipper, uint256 amount);

    constructor() {
        creator = payable(msg.sender);
    }

    function tip() public payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        totalTips += msg.value;
        emit Tipped(msg.sender, msg.value);
    }

    function withdraw() public {
        require(msg.sender == creator, "Only the creator can withdraw.");
        uint256 balance = address(this).balance;
        creator.transfer(balance);
    }
}
