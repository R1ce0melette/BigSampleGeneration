// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleEscrow
 * @dev A simple escrow contract to facilitate a transaction between a buyer and a seller,
 * with a mediator to resolve disputes.
 */
contract SimpleEscrow {
    enum State { Created, Locked, InDispute, Released, Refunded }

    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    State public currentState;

    /**
     * @dev Emitted when the contract is initialized.
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     * @param mediator The address of the mediator.
     * @param amount The amount of ETH in escrow.
     */
    event Initialized(address indexed buyer, address indexed seller, address indexed mediator, uint256 amount);

    /**
     * @dev Emitted when the buyer deposits funds into the escrow.
     * @param amount The amount deposited.
     */
    event FundsDeposited(uint256 amount);

    /**
     * @dev Emitted when the funds are released to the seller.
     * @param amount The amount released.
     */
    event FundsReleased(uint256 amount);

    /**
     * @dev Emitted when the funds are refunded to the buyer.
     * @param amount The amount refunded.
     */
    event FundsRefunded(uint256 amount);

    /**
     * @dev Emitted when a dispute is raised by the buyer.
     */
    event DisputeRaised();

    /**
     * @dev Emitted when a dispute is resolved by the mediator.
     * @param resolvedTo The address to which the funds were resolved (seller or buyer).
     */
    event DisputeResolved(address indexed resolvedTo);

    /**
     * @dev Modifier to check the current state of the escrow.
     * @param _state The expected state.
     */
    modifier inState(State _state) {
        require(currentState == _state, "Invalid state for this action.");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is the buyer.
     */
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can perform this action.");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is the seller.
     */
    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can perform this action.");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is the mediator.
     */
    modifier onlyMediator() {
        require(msg.sender == mediator, "Only the mediator can perform this action.");
        _;
    }

    /**
     * @dev Sets up the escrow with the parties involved.
     * @param _seller The address of the seller.
     * @param _mediator The address of the mediator.
     */
    constructor(address _seller, address _mediator) {
        buyer = msg.sender;
        seller = _seller;
        mediator = _mediator;
        currentState = State.Created;
        emit Initialized(buyer, seller, mediator, 0);
    }

    /**
     * @dev Allows the buyer to deposit funds into the escrow.
     */
    function deposit() public payable onlyBuyer inState(State.Created) {
        amount = msg.value;
        require(amount > 0, "Deposit amount must be greater than zero.");
        currentState = State.Locked;
        emit FundsDeposited(amount);
    }

    /**
     * @dev Allows the buyer to confirm receipt and release the funds to the seller.
     */
    function release() public onlyBuyer inState(State.Locked) {
        currentState = State.Released;
        payable(seller).transfer(amount);
        emit FundsReleased(amount);
    }

    /**
     * @dev Allows the buyer to raise a dispute, putting the funds under the mediator's control.
     */
    function raiseDispute() public onlyBuyer inState(State.Locked) {
        currentState = State.InDispute;
        emit DisputeRaised();
    }

    /**
     * @dev Allows the mediator to resolve a dispute in favor of the seller.
     */
    function resolveForSeller() public onlyMediator inState(State.InDispute) {
        currentState = State.Released;
        payable(seller).transfer(amount);
        emit DisputeResolved(seller);
    }

    /**
     * @dev Allows the mediator to resolve a dispute in favor of the buyer.
     */
    function resolveForBuyer() public onlyMediator inState(State.InDispute) {
        currentState = State.Refunded;
        payable(buyer).transfer(amount);
        emit DisputeResolved(buyer);
    }
}
