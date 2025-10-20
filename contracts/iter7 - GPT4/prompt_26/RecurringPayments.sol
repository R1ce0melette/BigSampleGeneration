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
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Amount must be positive");
        require(msg.value == amount, "Send amount to lock");
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
        emit PaymentAuthorized(nextPaymentId, msg.sender, payee, amount, frequency);
        nextPaymentId++;
    }

    function executePayment(uint256 id) external {
        Payment storage p = payments[id];
        require(p.active, "Payment not active");
        require(block.timestamp >= p.nextPaymentTime, "Too early");
        require(address(this).balance >= p.amount, "Insufficient contract balance");
        p.payee.transfer(p.amount);
        emit PaymentExecuted(id, p.payer, p.payee, p.amount);
        uint256 interval = p.frequency == Frequency.Weekly ? 7 days : 30 days;
        p.nextPaymentTime += interval;
    }

    function cancelPayment(uint256 id) external {
        Payment storage p = payments[id];
        require(p.active, "Payment not active");
        require(p.payer == msg.sender, "Not payer");
        p.active = false;
        payable(p.payer).transfer(p.amount);
        emit PaymentCancelled(id);
    }

    function getUserPayments(address user) external view returns (uint256[] memory) {
        return userPayments[user];
    }
}
