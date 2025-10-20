// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public creator;
    uint256 public totalTips;

    event Tipped(address indexed tipper, uint256 amount);
    event Withdrawn(address indexed creator, uint256 amount);

    constructor(address payable _creator) {
        require(_creator != address(0), "Creator address cannot be the zero address.");
        creator = _creator;
    }

    function tip() public payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        totalTips += msg.value;
        emit Tipped(msg.sender, msg.value);
    }

    function withdraw() public {
        require(msg.sender == creator, "Only the creator can withdraw tips.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw.");

        emit Withdrawn(creator, balance);
        creator.transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
