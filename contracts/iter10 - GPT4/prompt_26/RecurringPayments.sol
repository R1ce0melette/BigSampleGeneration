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

    mapping(address => Payment[]) public userPayments;

    event PaymentAuthorized(address indexed payer, address indexed payee, uint256 amount, Frequency frequency);
    event PaymentExecuted(address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(address indexed payer, uint256 index);

    function authorizePayment(address payable payee, uint256 amount, Frequency frequency) external payable {
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Amount must be positive");
        uint256 interval = frequency == Frequency.Weekly ? 7 days : 30 days;
        userPayments[msg.sender].push(Payment({
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
        Payment storage payment = userPayments[payer][index];
        require(payment.active, "Payment not active");
        require(block.timestamp >= payment.nextPaymentTime, "Too early");
        require(address(this).balance >= payment.amount, "Insufficient contract balance");
        payment.nextPaymentTime += payment.frequency == Frequency.Weekly ? 7 days : 30 days;
        payment.payee.transfer(payment.amount);
        emit PaymentExecuted(payer, payment.payee, payment.amount);
    }

    function cancelPayment(uint256 index) external {
        Payment storage payment = userPayments[msg.sender][index];
        require(payment.active, "Already cancelled");
        payment.active = false;
        emit PaymentCancelled(msg.sender, index);
    }

    function fundContract() external payable {}

    function getPayments(address user) external view returns (Payment[] memory) {
        return userPayments[user];
    }
}
