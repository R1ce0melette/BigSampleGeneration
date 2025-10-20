// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {
    enum Frequency { Weekly, Monthly }

    struct Payment {
        address payable recipient;
        uint256 amount;
        Frequency frequency;
        uint256 nextPaymentTime;
        bool active;
    }

    mapping(address => Payment[]) public userPayments;

    function authorizePayment(address payable recipient, uint256 amount, Frequency frequency) external payable {
        require(msg.value == amount, "Send amount to lock");
        uint256 interval = frequency == Frequency.Weekly ? 7 days : 30 days;
        userPayments[msg.sender].push(Payment(recipient, amount, frequency, block.timestamp + interval, true));
    }

    function executePayment(address user, uint256 index) external {
        Payment storage p = userPayments[user][index];
        require(p.active, "Inactive");
        require(block.timestamp >= p.nextPaymentTime, "Too early");
        p.recipient.transfer(p.amount);
        uint256 interval = p.frequency == Frequency.Weekly ? 7 days : 30 days;
        p.nextPaymentTime += interval;
    }

    function cancelPayment(uint256 index) external {
        Payment storage p = userPayments[msg.sender][index];
        require(p.active, "Inactive");
        p.active = false;
        payable(msg.sender).transfer(p.amount);
    }

    function getPayment(address user, uint256 index) external view returns (address, uint256, Frequency, uint256, bool) {
        Payment storage p = userPayments[user][index];
        return (p.recipient, p.amount, p.frequency, p.nextPaymentTime, p.active);
    }
}
