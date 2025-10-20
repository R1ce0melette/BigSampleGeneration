// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    uint256 public monthlyFee;
    address public owner;
    mapping(address => uint256) public subscriptions;

    event Subscribed(address indexed user, uint256 until);
    event FeeChanged(uint256 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _monthlyFee) {
        require(_monthlyFee > 0, "Fee must be positive");
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }

    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect fee");
        uint256 current = block.timestamp > subscriptions[msg.sender] ? block.timestamp : subscriptions[msg.sender];
        subscriptions[msg.sender] = current + 30 days;
        emit Subscribed(msg.sender, subscriptions[msg.sender]);
    }

    function setMonthlyFee(uint256 newFee) external onlyOwner {
        require(newFee > 0, "Fee must be positive");
        monthlyFee = newFee;
        emit FeeChanged(newFee);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds");
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Withdraw failed");
    }

    function isSubscribed(address user) external view returns (bool) {
        return subscriptions[user] >= block.timestamp;
    }
}
