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

    event PaymentAuthorized(uint256 indexed id, address indexed payer, address indexed payee, uint256 amount, Frequency frequency);
    event PaymentExecuted(uint256 indexed id, address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(uint256 indexed id);

    function authorizePayment(address payable payee, uint256 amount, Frequency frequency) external payable {
        require(amount > 0, "Amount must be positive");
        require(msg.value == amount, "Send initial payment");
        uint256 interval = frequency == Frequency.Weekly ? 7 days : 30 days;
        payments[nextPaymentId] = Payment({
            payer: msg.sender,
            payee: payee,
            amount: amount,
            frequency: frequency,
            nextPaymentTime: block.timestamp + interval,
            active: true
        });
        userPayments[msg.sender].push(nextPaymentId);
        payee.transfer(amount);
        emit PaymentAuthorized(nextPaymentId, msg.sender, payee, amount, frequency);
        emit PaymentExecuted(nextPaymentId, msg.sender, payee, amount);
        nextPaymentId++;
    }

    function executePayment(uint256 id) external payable {
        Payment storage p = payments[id];
        require(p.active, "Payment not active");
        require(msg.sender == p.payer, "Not payer");
        require(block.timestamp >= p.nextPaymentTime, "Too early");
        require(msg.value == p.amount, "Incorrect amount");
        uint256 interval = p.frequency == Frequency.Weekly ? 7 days : 30 days;
        p.nextPaymentTime += interval;
        p.payee.transfer(msg.value);
        emit PaymentExecuted(id, p.payer, p.payee, msg.value);
    }

    function cancelPayment(uint256 id) external {
        Payment storage p = payments[id];
        require(p.active, "Payment not active");
        require(msg.sender == p.payer, "Not payer");
        p.active = false;
        emit PaymentCancelled(id);
    }

    function getUserPayments(address user) external view returns (uint256[] memory) {
        return userPayments[user];
    }
}
