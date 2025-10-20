// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayment {
    enum Frequency { Weekly, Monthly }

    struct Payment {
        address payer;
        address payable payee;
        uint256 amount;
        Frequency frequency;
        uint256 nextPayment;
        bool active;
    }

    mapping(address => Payment[]) public payments;

    event PaymentAuthorized(address indexed payer, address indexed payee, uint256 amount, Frequency frequency);
    event PaymentExecuted(address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(address indexed payer, uint256 index);

    function authorizePayment(address payable payee, uint256 amount, Frequency frequency) external payable {
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Amount must be positive");
        uint256 interval = frequency == Frequency.Weekly ? 7 days : 30 days;
        payments[msg.sender].push(Payment(msg.sender, payee, amount, frequency, block.timestamp + interval, true));
        emit PaymentAuthorized(msg.sender, payee, amount, frequency);
    }

    function executePayment(address payer, uint256 index) external {
        Payment storage p = payments[payer][index];
        require(p.active, "Inactive");
        require(block.timestamp >= p.nextPayment, "Too early");
        require(address(this).balance >= p.amount, "Insufficient contract balance");
        p.nextPayment = p.frequency == Frequency.Weekly ? p.nextPayment + 7 days : p.nextPayment + 30 days;
        (bool sent, ) = p.payee.call{value: p.amount}("");
        require(sent, "Transfer failed");
        emit PaymentExecuted(payer, p.payee, p.amount);
    }

    function cancelPayment(uint256 index) external {
        Payment storage p = payments[msg.sender][index];
        require(p.active, "Inactive");
        p.active = false;
        emit PaymentCancelled(msg.sender, index);
    }

    receive() external payable {}
}
