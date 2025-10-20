// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public creator;
    uint256 public totalTips;

    event Tipped(address indexed sender, uint256 amount);

    constructor() {
        creator = msg.sender;
    }

    function tip() external payable {
        require(msg.value > 0, "Tip must be greater than zero");
        totalTips += msg.value;
        emit Tipped(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == creator, "Only creator can withdraw");
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        payable(creator).transfer(amount);
    }
}
