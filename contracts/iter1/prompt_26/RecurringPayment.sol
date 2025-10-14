// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayment {
    struct Payment {
        address payer;
        address payee;
        uint256 amount;
        uint256 interval;
        uint256 nextPayment;
        bool active;
    }

    uint256 public nextPaymentId;
    mapping(uint256 => Payment) public payments;

    event PaymentAuthorized(uint256 indexed id, address indexed payer, address indexed payee, uint256 amount, uint256 interval);
    event PaymentExecuted(uint256 indexed id, address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(uint256 indexed id);

    function authorizePayment(address payee, uint256 amount, uint256 interval) external {
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Amount must be positive");
        require(interval == 30 days || interval == 7 days, "Interval must be weekly or monthly");
        payments[nextPaymentId] = Payment(msg.sender, payee, amount, interval, block.timestamp + interval, true);
        emit PaymentAuthorized(nextPaymentId, msg.sender, payee, amount, interval);
        nextPaymentId++;
    }

    function executePayment(uint256 paymentId) external {
        Payment storage p = payments[paymentId];
        require(p.active, "Payment not active");
        require(block.timestamp >= p.nextPayment, "Too early");
        require(address(this).balance >= p.amount, "Insufficient contract balance");
        p.nextPayment += p.interval;
        payable(p.payee).transfer(p.amount);
        emit PaymentExecuted(paymentId, p.payer, p.payee, p.amount);
    }

    function cancelPayment(uint256 paymentId) external {
        Payment storage p = payments[paymentId];
        require(msg.sender == p.payer, "Not payer");
        require(p.active, "Already cancelled");
        p.active = false;
        emit PaymentCancelled(paymentId);
    }

    function fundContract() external payable {}
}
