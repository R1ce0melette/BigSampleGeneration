// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleEscrow
 * @dev A simple escrow contract to hold funds for a transaction between a buyer and a seller,
 * with a mediator to resolve disputes.
 */
contract SimpleEscrow {
    enum State { Created, Funded, Released, Disputed }

    address payable public buyer;
    address payable public seller;
    address public mediator;
    State public currentState;
    uint256 public amount;

    event Funded(uint256 amount);
    event Released(uint256 amount);
    event Disputed();
    event Resolved(address indexed winner, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this function.");
        _;
    }

    modifier onlyMediator() {
        require(msg.sender == mediator, "Only the mediator can call this function.");
        _;
    }

    modifier inState(State _state) {
        require(currentState == _state, "Invalid state for this action.");
        _;
    }

    /**
     * @dev Sets up the escrow with the buyer, seller, and mediator.
     * @param _seller The address of the seller.
     * @param _mediator The address of the mediator.
     */
    constructor(address payable _seller, address _mediator) {
        buyer = payable(msg.sender);
        seller = _seller;
        mediator = _mediator;
        currentState = State.Created;
    }

    /**
     * @dev The buyer deposits the funds into the escrow.
     */
    function deposit() external payable onlyBuyer inState(State.Created) {
        require(msg.value > 0, "Deposit must be greater than zero.");
        amount = msg.value;
        currentState = State.Funded;
        emit Funded(amount);
    }

    /**
     * @dev The buyer releases the funds to the seller.
     */
    function release() external onlyBuyer inState(State.Funded) {
        currentState = State.Released;
        (bool success, ) = seller.call{value: amount}("");
        require(success, "Transfer failed.");
        emit Released(amount);
    }

    /**
     * @dev The buyer or seller initiates a dispute.
     */
    function dispute() external inState(State.Funded) {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can dispute.");
        currentState = State.Disputed;
        emit Disputed();
    }

    /**
     * @dev The mediator resolves the dispute, sending funds to either the buyer or the seller.
     * @param _releaseToSeller True to release funds to the seller, false to refund the buyer.
     */
    function resolveDispute(bool _releaseToSeller) external onlyMediator inState(State.Disputed) {
        address payable winner = _releaseToSeller ? seller : buyer;
        
        (bool success, ) = winner.call{value: amount}("");
        require(success, "Transfer failed.");
        
        emit Resolved(winner, amount);
        // The contract can be considered closed after resolution. No state change needed
        // as no further actions are possible.
    }
}
