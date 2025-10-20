// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public creator;
    uint256 public totalTips;

    event Tipped(address indexed tipper, uint256 amount);

    constructor(address payable _creator) {
        creator = _creator;
    }

    function tip() public payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        totalTips += msg.value;
        creator.transfer(msg.value);
        emit Tipped(msg.sender, msg.value);
    }
}
