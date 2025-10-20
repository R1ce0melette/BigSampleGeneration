// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EscrowSystem
 * @dev Simple escrow system between a buyer and a seller with a mediator to resolve disputes
 */
contract EscrowSystem {
    // Escrow status enum
    enum EscrowStatus {
        Active,
        Completed,
        Refunded,
        Disputed,
        Resolved
    }

    // Escrow structure
    struct Escrow {
        uint256 id;
        address buyer;
        address seller;
        address mediator;
        uint256 amount;
        string description;
        EscrowStatus status;
        uint256 createdAt;
        uint256 completedAt;
        bool buyerApproved;
        bool sellerApproved;
        bool disputed;
    }

    // State variables
    address public owner;
    uint256 private escrowCounter;
    uint256 public mediatorFeePercent; // Fee in basis points (e.g., 100 = 1%)
    
    mapping(uint256 => Escrow) private escrows;
    mapping(address => uint256[]) private buyerEscrows;
    mapping(address => uint256[]) private sellerEscrows;
    mapping(address => uint256[]) private mediatorEscrows;
    
    uint256[] private allEscrowIds;

    // Events
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, address mediator, uint256 amount);
    event FundsDeposited(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCompleted(uint256 indexed escrowId, address indexed seller, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event DisputeRaised(uint256 indexed escrowId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed escrowId, address indexed resolvedBy, bool refundToBuyer);
    event BuyerApproved(uint256 indexed escrowId);
    event SellerApproved(uint256 indexed escrowId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier escrowExists(uint256 escrowId) {
        require(escrowId > 0 && escrowId <= escrowCounter, "Escrow does not exist");
        _;
    }

    modifier onlyBuyer(uint256 escrowId) {
        require(escrows[escrowId].buyer == msg.sender, "Not the buyer");
        _;
    }

    modifier onlySeller(uint256 escrowId) {
        require(escrows[escrowId].seller == msg.sender, "Not the seller");
        _;
    }

    modifier onlyMediator(uint256 escrowId) {
        require(escrows[escrowId].mediator == msg.sender, "Not the mediator");
        _;
    }

    modifier onlyActive(uint256 escrowId) {
        require(escrows[escrowId].status == EscrowStatus.Active, "Escrow is not active");
        _;
    }

    modifier onlyDisputed(uint256 escrowId) {
        require(escrows[escrowId].status == EscrowStatus.Disputed, "Escrow is not disputed");
        _;
    }

    constructor(uint256 _mediatorFeePercent) {
        owner = msg.sender;
        escrowCounter = 0;
        mediatorFeePercent = _mediatorFeePercent;
    }

    /**
     * @dev Create a new escrow
     * @param seller Seller address
     * @param mediator Mediator address
     * @param description Description of the transaction
     * @return escrowId ID of the created escrow
     */
    function createEscrow(
        address seller,
        address mediator,
        string memory description
    ) public payable returns (uint256) {
        require(msg.value > 0, "Must deposit funds");
        require(seller != address(0), "Invalid seller address");
        require(mediator != address(0), "Invalid mediator address");
        require(seller != msg.sender, "Seller cannot be buyer");
        require(mediator != msg.sender, "Mediator cannot be buyer");
        require(mediator != seller, "Mediator cannot be seller");

        escrowCounter++;
        uint256 escrowId = escrowCounter;

        Escrow storage newEscrow = escrows[escrowId];
        newEscrow.id = escrowId;
        newEscrow.buyer = msg.sender;
        newEscrow.seller = seller;
        newEscrow.mediator = mediator;
        newEscrow.amount = msg.value;
        newEscrow.description = description;
        newEscrow.status = EscrowStatus.Active;
        newEscrow.createdAt = block.timestamp;
        newEscrow.buyerApproved = false;
        newEscrow.sellerApproved = false;
        newEscrow.disputed = false;

        buyerEscrows[msg.sender].push(escrowId);
        sellerEscrows[seller].push(escrowId);
        mediatorEscrows[mediator].push(escrowId);
        allEscrowIds.push(escrowId);

        emit EscrowCreated(escrowId, msg.sender, seller, mediator, msg.value);
        emit FundsDeposited(escrowId, msg.sender, msg.value);

        return escrowId;
    }

    /**
     * @dev Buyer approves release of funds to seller
     * @param escrowId Escrow ID
     */
    function buyerApprove(uint256 escrowId) 
        public 
        escrowExists(escrowId)
        onlyBuyer(escrowId)
        onlyActive(escrowId)
    {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.buyerApproved, "Already approved");

        escrow.buyerApproved = true;

        emit BuyerApproved(escrowId);

        // If both parties approved, complete escrow
        if (escrow.sellerApproved) {
            _completeEscrow(escrowId);
        }
    }

    /**
     * @dev Seller confirms readiness to receive funds
     * @param escrowId Escrow ID
     */
    function sellerApprove(uint256 escrowId) 
        public 
        escrowExists(escrowId)
        onlySeller(escrowId)
        onlyActive(escrowId)
    {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.sellerApproved, "Already approved");

        escrow.sellerApproved = true;

        emit SellerApproved(escrowId);

        // If both parties approved, complete escrow
        if (escrow.buyerApproved) {
            _completeEscrow(escrowId);
        }
    }

    /**
     * @dev Complete escrow and release funds to seller
     * @param escrowId Escrow ID
     */
    function _completeEscrow(uint256 escrowId) private {
        Escrow storage escrow = escrows[escrowId];
        
        escrow.status = EscrowStatus.Completed;
        escrow.completedAt = block.timestamp;

        uint256 amount = escrow.amount;
        payable(escrow.seller).transfer(amount);

        emit EscrowCompleted(escrowId, escrow.seller, amount);
    }

    /**
     * @dev Raise a dispute
     * @param escrowId Escrow ID
     */
    function raiseDispute(uint256 escrowId) 
        public 
        escrowExists(escrowId)
        onlyActive(escrowId)
    {
        Escrow storage escrow = escrows[escrowId];
        require(
            msg.sender == escrow.buyer || msg.sender == escrow.seller,
            "Only buyer or seller can raise dispute"
        );
        require(!escrow.disputed, "Dispute already raised");

        escrow.disputed = true;
        escrow.status = EscrowStatus.Disputed;

        emit DisputeRaised(escrowId, msg.sender);
    }

    /**
     * @dev Mediator resolves dispute
     * @param escrowId Escrow ID
     * @param refundToBuyer true to refund buyer, false to pay seller
     */
    function resolveDispute(uint256 escrowId, bool refundToBuyer) 
        public 
        escrowExists(escrowId)
        onlyMediator(escrowId)
        onlyDisputed(escrowId)
    {
        Escrow storage escrow = escrows[escrowId];
        
        escrow.status = EscrowStatus.Resolved;
        escrow.completedAt = block.timestamp;

        uint256 amount = escrow.amount;
        uint256 mediatorFee = (amount * mediatorFeePercent) / 10000;
        uint256 amountAfterFee = amount - mediatorFee;

        // Pay mediator fee
        if (mediatorFee > 0) {
            payable(escrow.mediator).transfer(mediatorFee);
        }

        // Pay buyer or seller based on resolution
        if (refundToBuyer) {
            payable(escrow.buyer).transfer(amountAfterFee);
            emit EscrowRefunded(escrowId, escrow.buyer, amountAfterFee);
        } else {
            payable(escrow.seller).transfer(amountAfterFee);
            emit EscrowCompleted(escrowId, escrow.seller, amountAfterFee);
        }

        emit DisputeResolved(escrowId, msg.sender, refundToBuyer);
    }

    /**
     * @dev Get escrow details
     * @param escrowId Escrow ID
     * @return Escrow details
     */
    function getEscrow(uint256 escrowId) 
        public 
        view 
        escrowExists(escrowId)
        returns (Escrow memory) 
    {
        return escrows[escrowId];
    }

    /**
     * @dev Get all escrows
     * @return Array of all escrows
     */
    function getAllEscrows() public view returns (Escrow[] memory) {
        Escrow[] memory allEscrows = new Escrow[](allEscrowIds.length);
        
        for (uint256 i = 0; i < allEscrowIds.length; i++) {
            allEscrows[i] = escrows[allEscrowIds[i]];
        }
        
        return allEscrows;
    }

    /**
     * @dev Get buyer's escrows
     * @param buyer Buyer address
     * @return Array of escrow IDs
     */
    function getBuyerEscrows(address buyer) public view returns (uint256[] memory) {
        return buyerEscrows[buyer];
    }

    /**
     * @dev Get seller's escrows
     * @param seller Seller address
     * @return Array of escrow IDs
     */
    function getSellerEscrows(address seller) public view returns (uint256[] memory) {
        return sellerEscrows[seller];
    }

    /**
     * @dev Get mediator's escrows
     * @param mediator Mediator address
     * @return Array of escrow IDs
     */
    function getMediatorEscrows(address mediator) public view returns (uint256[] memory) {
        return mediatorEscrows[mediator];
    }

    /**
     * @dev Get escrows by status
     * @param status Escrow status
     * @return Array of escrows with the specified status
     */
    function getEscrowsByStatus(EscrowStatus status) public view returns (Escrow[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allEscrowIds.length; i++) {
            if (escrows[allEscrowIds[i]].status == status) {
                count++;
            }
        }

        Escrow[] memory result = new Escrow[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allEscrowIds.length; i++) {
            Escrow memory escrow = escrows[allEscrowIds[i]];
            if (escrow.status == status) {
                result[index] = escrow;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get active escrows
     * @return Array of active escrows
     */
    function getActiveEscrows() public view returns (Escrow[] memory) {
        return getEscrowsByStatus(EscrowStatus.Active);
    }

    /**
     * @dev Get disputed escrows
     * @return Array of disputed escrows
     */
    function getDisputedEscrows() public view returns (Escrow[] memory) {
        return getEscrowsByStatus(EscrowStatus.Disputed);
    }

    /**
     * @dev Get completed escrows
     * @return Array of completed escrows
     */
    function getCompletedEscrows() public view returns (Escrow[] memory) {
        return getEscrowsByStatus(EscrowStatus.Completed);
    }

    /**
     * @dev Get buyer's escrow details
     * @param buyer Buyer address
     * @return Array of escrows
     */
    function getBuyerEscrowDetails(address buyer) public view returns (Escrow[] memory) {
        uint256[] memory ids = buyerEscrows[buyer];
        Escrow[] memory result = new Escrow[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = escrows[ids[i]];
        }

        return result;
    }

    /**
     * @dev Get seller's escrow details
     * @param seller Seller address
     * @return Array of escrows
     */
    function getSellerEscrowDetails(address seller) public view returns (Escrow[] memory) {
        uint256[] memory ids = sellerEscrows[seller];
        Escrow[] memory result = new Escrow[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = escrows[ids[i]];
        }

        return result;
    }

    /**
     * @dev Get mediator's escrow details
     * @param mediator Mediator address
     * @return Array of escrows
     */
    function getMediatorEscrowDetails(address mediator) public view returns (Escrow[] memory) {
        uint256[] memory ids = mediatorEscrows[mediator];
        Escrow[] memory result = new Escrow[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = escrows[ids[i]];
        }

        return result;
    }

    /**
     * @dev Get total escrow count
     * @return Total number of escrows
     */
    function getTotalEscrowCount() public view returns (uint256) {
        return escrowCounter;
    }

    /**
     * @dev Get escrow count by status
     * @param status Escrow status
     * @return Count of escrows with the specified status
     */
    function getEscrowCountByStatus(EscrowStatus status) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allEscrowIds.length; i++) {
            if (escrows[allEscrowIds[i]].status == status) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get contract balance
     * @return Current contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Update mediator fee percent
     * @param newFeePercent New fee percent in basis points
     */
    function setMediatorFeePercent(uint256 newFeePercent) public onlyOwner {
        require(newFeePercent <= 1000, "Fee cannot exceed 10%");
        mediatorFeePercent = newFeePercent;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }
}
