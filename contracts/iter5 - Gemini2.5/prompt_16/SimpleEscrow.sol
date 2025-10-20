// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleEscrow
 * @dev A basic escrow contract to hold funds for a transaction between a buyer and a seller, with a mediator for disputes.
 */
contract SimpleEscrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;

    enum EscrowState { Created, Funded, Disputed, Released }
    EscrowState public currentState;

    /**
     * @dev Event emitted when the escrow is funded by the buyer.
     * @param _buyer The address of the buyer.
     * @param _amount The amount deposited into escrow.
     */
    event Funded(address indexed _buyer, uint256 _amount);

    /**
     * @dev Event emitted when the funds are released to the seller.
     * @param _seller The address of the seller.
     * @param _amount The amount released.
     */
    event Released(address indexed _seller, uint256 _amount);

    /**
     * @dev Event emitted when a dispute is raised.
     * @param _disputer The address of the party who raised the dispute.
     */
    event Disputed(address indexed _disputer);

    /**
     * @dev Event emitted when a dispute is resolved by the mediator.
     * @param _resolver The address of the mediator.
     * @param _recipient The address receiving the funds after resolution.
     * @param _amount The amount resolved.
     */
    event DisputeResolved(address indexed _resolver, address indexed _recipient, uint256 _amount);

    /**
     * @dev Sets up the escrow with the buyer, seller, and mediator.
     * @param _buyer The address of the buyer.
     * @param _seller The address of the seller.
     * @param _mediator The address of the mediator.
     */
    constructor(address _buyer, address _seller, address _mediator) {
        require(_buyer != address(0) && _seller != address(0) && _mediator != address(0), "Addresses cannot be zero.");
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
        currentState = EscrowState.Created;
    }

    /**
     * @dev Allows the buyer to fund the escrow.
     * - Only the buyer can fund.
     * - The escrow must be in the 'Created' state.
     */
    function fund() public payable {
        require(msg.sender == buyer, "Only the buyer can fund the escrow.");
        require(currentState == EscrowState.Created, "Escrow is not in the created state.");
        
        amount = msg.value;
        isFunded = true;
        currentState = EscrowState.Funded;
        emit Funded(buyer, amount);
    }

    /**
     * @dev Allows the buyer to release the funds to the seller.
     * - Only the buyer can release.
     * - The escrow must be funded and not in dispute.
     */
    function release() public {
        require(msg.sender == buyer, "Only the buyer can release the funds.");
        require(currentState == EscrowState.Funded, "Escrow is not in a fundable state to be released.");
        
        isReleased = true;
        currentState = EscrowState.Released;
        emit Released(seller, amount);
        payable(seller).transfer(amount);
    }

    /**
     * @dev Allows either the buyer or seller to raise a dispute.
     * - The escrow must be funded.
     */
    function raiseDispute() public {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can raise a dispute.");
        require(currentState == EscrowState.Funded, "Dispute can only be raised when funded.");
        
        currentState = EscrowState.Disputed;
        emit Disputed(msg.sender);
    }

    /**
     * @dev Allows the mediator to resolve a dispute, sending funds to either buyer or seller.
     * - Only the mediator can resolve.
     * - The escrow must be in a disputed state.
     * @param _sendToBuyer If true, funds go to the buyer; otherwise, to the seller.
     */
    function resolveDispute(bool _sendToBuyer) public {
        require(msg.sender == mediator, "Only the mediator can resolve disputes.");
        require(currentState == EscrowState.Disputed, "Escrow is not in a disputed state.");

        address recipient = _sendToBuyer ? buyer : seller;
        isReleased = true;
        currentState = EscrowState.Released;
        
        emit DisputeResolved(mediator, recipient, amount);
        payable(recipient).transfer(amount);
    }
}
