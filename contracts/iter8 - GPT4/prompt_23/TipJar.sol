// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public creator;
    uint256 public totalTips;

    event Tipped(address indexed from, uint256 amount);
    event Withdrawn(address indexed creator, uint256 amount);

    constructor() {
        creator = msg.sender;
    }

    function tip() external payable {
        require(msg.value > 0, "No ETH sent");
        totalTips += msg.value;
        emit Tipped(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == creator, "Not creator");
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds");
        (bool sent, ) = creator.call{value: amount}("");
        require(sent, "Withdraw failed");
        emit Withdrawn(creator, amount);
    }
}
