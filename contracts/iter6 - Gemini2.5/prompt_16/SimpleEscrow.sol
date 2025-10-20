// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleEscrow
 * @dev A simple escrow contract to facilitate a transaction between a buyer and a seller,
 * with a mediator to resolve disputes.
 */
contract SimpleEscrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;
    bool public isDisputed;

    /**
     * @dev Emitted when the escrow is funded by the buyer.
     * @param buyer The address of the buyer.
     * @param amount The amount of ETH funded.
     */
    event Funded(address indexed buyer, uint256 amount);

    /**
     * @dev Emitted when the funds are released to the seller.
     * @param seller The address of the seller.
     * @param amount The amount of ETH released.
     */
    event Released(address indexed seller, uint256 amount);

    /**
     * @dev Emitted when a dispute is raised by the buyer.
     * @param buyer The address of the buyer who raised the dispute.
     */
    event Disputed(address indexed buyer);

    /**
     * @dev Emitted when a dispute is resolved by the mediator.
     * @param mediator The address of the mediator.
     * @param recipient The address that received the funds after resolution.
     * @param amount The amount of ETH transferred.
     */
    event DisputeResolved(address indexed mediator, address indexed recipient, uint256 amount);

    /**
     * @dev Sets up the escrow with the buyer, seller, and mediator.
     * @param _seller The address of the seller.
     * @param _mediator The address of the mediator.
     */
    constructor(address _seller, address _mediator) {
        buyer = msg.sender;
        seller = _seller;
        mediator = _mediator;
    }

    /**
     * @dev Allows the buyer to fund the escrow.
     */
    function fund() public payable {
        require(msg.sender == buyer, "Only the buyer can fund the escrow.");
        require(!isFunded, "Escrow is already funded.");
        amount = msg.value;
        isFunded = true;
        emit Funded(buyer, amount);
    }

    /**
     * @dev Allows the buyer to release the funds to the seller.
     */
    function release() public {
        require(msg.sender == buyer, "Only the buyer can release the funds.");
        require(isFunded, "Escrow is not funded.");
        require(!isReleased, "Funds have already been released.");
        require(!isDisputed, "A dispute is active.");

        isReleased = true;
        (bool success, ) = seller.call{value: amount}("");
        require(success, "Failed to release funds to the seller.");
        emit Released(seller, amount);
    }

    /**
     * @dev Allows the buyer to raise a dispute.
     */
    function raiseDispute() public {
        require(msg.sender == buyer, "Only the buyer can raise a dispute.");
        require(isFunded, "Escrow is not funded.");
        require(!isReleased, "Funds have already been released.");
        isDisputed = true;
        emit Disputed(buyer);
    }

    /**
     * @dev Allows the mediator to resolve a dispute, sending funds to either the buyer or the seller.
     * @param _sendToSeller True to send funds to the seller, false to refund the buyer.
     */
    function resolveDispute(bool _sendToSeller) public {
        require(msg.sender == mediator, "Only the mediator can resolve disputes.");
        require(isDisputed, "No dispute is active.");

        isReleased = true;
        address recipient = _sendToSeller ? seller : buyer;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to transfer funds upon dispute resolution.");
        emit DisputeResolved(mediator, recipient, amount);
    }
}
