// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    address public owner;
    uint256 public monthlyFee;
    mapping(address => uint256) public paidUntil;

    event Subscribed(address indexed user, uint256 until);
    event FeeChanged(uint256 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _monthlyFee) {
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }

    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect fee");
        uint256 newPaidUntil = block.timestamp > paidUntil[msg.sender] ? block.timestamp : paidUntil[msg.sender];
        newPaidUntil += 30 days;
        paidUntil[msg.sender] = newPaidUntil;
        emit Subscribed(msg.sender, newPaidUntil);
    }

    function setMonthlyFee(uint256 _fee) external onlyOwner {
        monthlyFee = _fee;
        emit FeeChanged(_fee);
    }

    function isSubscribed(address user) external view returns (bool) {
        return paidUntil[user] >= block.timestamp;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
