// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    uint256 public monthlyFee;
    mapping(address => uint256) public paidUntil;
    address public owner;

    constructor(uint256 _monthlyFee) {
        monthlyFee = _monthlyFee;
        owner = msg.sender;
    }

    function subscribe(uint256 months) external payable {
        require(months > 0, "Months must be positive");
        require(msg.value == months * monthlyFee, "Incorrect ETH sent");
        uint256 newPaidUntil = block.timestamp + (months * 30 days);
        if (paidUntil[msg.sender] < block.timestamp) {
            paidUntil[msg.sender] = newPaidUntil;
        } else {
            paidUntil[msg.sender] += months * 30 days;
        }
    }

    function isActive(address user) external view returns (bool) {
        return paidUntil[user] >= block.timestamp;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}
