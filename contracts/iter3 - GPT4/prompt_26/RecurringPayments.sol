// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {
    enum Frequency { Weekly, Monthly }

    struct Payment {
        address payer;
        address payable payee;
        uint256 amount;
        Frequency frequency;
        uint256 nextPaymentTime;
        bool active;
    }

    uint256 public nextPaymentId;
    mapping(uint256 => Payment) public payments;
    mapping(address => uint256[]) public userPayments;

    event PaymentAuthorized(uint256 id, address indexed payer, address indexed payee, uint256 amount, Frequency frequency);
    event PaymentExecuted(uint256 id, address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(uint256 id);

    function authorizePayment(address payable payee, uint256 amount, Frequency frequency) external payable {
        require(msg.value == amount, "Send amount to lock");
        uint256 interval = frequency == Frequency.Weekly ? 7 days : 30 days;
        payments[nextPaymentId] = Payment(msg.sender, payee, amount, frequency, block.timestamp + interval, true);
        userPayments[msg.sender].push(nextPaymentId);
        emit PaymentAuthorized(nextPaymentId, msg.sender, payee, amount, frequency);
        nextPaymentId++;
    }

    function executePayment(uint256 paymentId) external {
        Payment storage p = payments[paymentId];
        require(p.active, "Inactive");
        require(block.timestamp >= p.nextPaymentTime, "Too early");
        p.payee.transfer(p.amount);
        uint256 interval = p.frequency == Frequency.Weekly ? 7 days : 30 days;
        p.nextPaymentTime += interval;
        emit PaymentExecuted(paymentId, p.payer, p.payee, p.amount);
    }

    function cancelPayment(uint256 paymentId) external {
        Payment storage p = payments[paymentId];
        require(p.payer == msg.sender, "Not payer");
        require(p.active, "Inactive");
        p.active = false;
        payable(p.payer).transfer(p.amount);
        emit PaymentCancelled(paymentId);
    }

    function getUserPayments(address user) external view returns (uint256[] memory) {
        return userPayments[user];
    }
}
