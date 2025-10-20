// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {
    enum Period { Weekly, Monthly }

    struct Payment {
        address payer;
        address payable payee;
        uint256 amount;
        Period period;
        uint256 nextPayment;
        bool active;
    }

    mapping(address => Payment[]) public payments;

    event PaymentAuthorized(address indexed payer, address indexed payee, uint256 amount, Period period);
    event PaymentExecuted(address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(address indexed payer, uint256 index);

    function authorizePayment(address payable payee, uint256 amount, Period period) external payable {
        require(amount > 0, "Amount must be positive");
        require(msg.value == amount, "Send amount to lock");
        uint256 next = block.timestamp + (period == Period.Weekly ? 7 days : 30 days);
        payments[msg.sender].push(Payment({
            payer: msg.sender,
            payee: payee,
            amount: amount,
            period: period,
            nextPayment: next,
            active: true
        }));
        emit PaymentAuthorized(msg.sender, payee, amount, period);
    }

    function executePayment(address payer, uint256 index) external {
        Payment storage p = payments[payer][index];
        require(p.active, "Not active");
        require(block.timestamp >= p.nextPayment, "Too early");
        p.payee.transfer(p.amount);
        p.nextPayment = block.timestamp + (p.period == Period.Weekly ? 7 days : 30 days);
        emit PaymentExecuted(payer, p.payee, p.amount);
    }

    function cancelPayment(uint256 index) external {
        Payment storage p = payments[msg.sender][index];
        require(p.active, "Not active");
        p.active = false;
        payable(msg.sender).transfer(p.amount);
        emit PaymentCancelled(msg.sender, index);
    }

    function getPayments(address user) external view returns (Payment[] memory) {
        return payments[user];
    }
}
