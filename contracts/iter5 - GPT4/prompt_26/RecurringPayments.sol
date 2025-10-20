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

    mapping(address => Payment[]) public payments;

    event PaymentAuthorized(address indexed payer, address indexed payee, uint256 amount, Frequency frequency);
    event PaymentExecuted(address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(address indexed payer, uint256 index);

    function authorizePayment(address payable payee, uint256 amount, Frequency frequency) external payable {
        require(amount > 0, "Amount must be positive");
        uint256 interval = frequency == Frequency.Weekly ? 7 days : 30 days;
        payments[msg.sender].push(Payment({
            payer: msg.sender,
            payee: payee,
            amount: amount,
            frequency: frequency,
            nextPaymentTime: block.timestamp + interval,
            active: true
        }));
        emit PaymentAuthorized(msg.sender, payee, amount, frequency);
    }

    function executePayment(address payer, uint256 index) external {
        Payment storage p = payments[payer][index];
        require(p.active, "Payment not active");
        require(block.timestamp >= p.nextPaymentTime, "Too early");
        require(address(payer).balance >= p.amount, "Insufficient balance");
        p.nextPaymentTime += (p.frequency == Frequency.Weekly ? 7 days : 30 days);
        p.payee.transfer(p.amount);
        emit PaymentExecuted(payer, p.payee, p.amount);
    }

    function cancelPayment(uint256 index) external {
        Payment storage p = payments[msg.sender][index];
        require(p.active, "Already cancelled");
        p.active = false;
        emit PaymentCancelled(msg.sender, index);
    }

    function getPayments(address user) external view returns (Payment[] memory) {
        return payments[user];
    }
}
