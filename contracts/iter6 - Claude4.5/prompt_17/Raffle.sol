// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Raffle
 * @dev An on-chain raffle where participants pay to enter and one random winner gets the pot
 */
contract Raffle {
    address public owner;
    uint256 public ticketPrice;
    uint256 public raffleId;
    
    enum RaffleState { OPEN, DRAWING, CLOSED }
    
    struct RaffleRound {
        uint256 id;
        uint256 ticketPrice;
        address[] participants;
        address winner;
        uint256 prizeAmount;
        uint256 startTime;
        uint256 endTime;
        RaffleState state;
    }
    
    mapping(uint256 => RaffleRound) public raffles;
    mapping(uint256 => mapping(address => uint256)) public ticketCount; // raffleId => participant => tickets
    
    // Events
    event RaffleStarted(uint256 indexed raffleId, uint256 ticketPrice, uint256 startTime);
    event TicketPurchased(uint256 indexed raffleId, address indexed participant, uint256 ticketCount);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prizeAmount);
    event RaffleClosed(uint256 indexed raffleId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor(uint256 _ticketPrice) {
        require(_ticketPrice > 0, "Ticket price must be greater than 0");
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }
    
    /**
     * @dev Start a new raffle
     */
    function startRaffle() external onlyOwner {
        if (raffleId > 0) {
            require(raffles[raffleId].state == RaffleState.CLOSED, "Current raffle is still active");
        }
        
        raffleId++;
        
        raffles[raffleId].id = raffleId;
        raffles[raffleId].ticketPrice = ticketPrice;
        raffles[raffleId].startTime = block.timestamp;
        raffles[raffleId].state = RaffleState.OPEN;
        
        emit RaffleStarted(raffleId, ticketPrice, block.timestamp);
    }
    
    /**
     * @dev Buy tickets for the current raffle
     * @param numTickets Number of tickets to purchase
     */
    function buyTickets(uint256 numTickets) external payable {
        require(raffleId > 0, "No active raffle");
        RaffleRound storage raffle = raffles[raffleId];
        
        require(raffle.state == RaffleState.OPEN, "Raffle is not open");
        require(numTickets > 0, "Must buy at least one ticket");
        require(msg.value == ticketPrice * numTickets, "Incorrect payment amount");
        
        // Add tickets for the participant
        for (uint256 i = 0; i < numTickets; i++) {
            raffle.participants.push(msg.sender);
        }
        
        ticketCount[raffleId][msg.sender] += numTickets;
        
        emit TicketPurchased(raffleId, msg.sender, numTickets);
    }
    
    /**
     * @dev Draw the winner and end the raffle
     */
    function drawWinner() external onlyOwner {
        require(raffleId > 0, "No active raffle");
        RaffleRound storage raffle = raffles[raffleId];
        
        require(raffle.state == RaffleState.OPEN, "Raffle is not open");
        require(raffle.participants.length > 0, "No participants in raffle");
        
        raffle.state = RaffleState.DRAWING;
        
        // Generate pseudo-random number
        uint256 randomIndex = _generateRandomNumber(raffle.participants.length);
        address winner = raffle.participants[randomIndex];
        
        raffle.winner = winner;
        raffle.prizeAmount = raffle.participants.length * raffle.ticketPrice;
        raffle.endTime = block.timestamp;
        raffle.state = RaffleState.CLOSED;
        
        // Transfer prize to winner
        (bool success, ) = winner.call{value: raffle.prizeAmount}("");
        require(success, "Transfer to winner failed");
        
        emit WinnerSelected(raffleId, winner, raffle.prizeAmount);
        emit RaffleClosed(raffleId);
    }
    
    /**
     * @dev Generate a pseudo-random number
     * @param max The maximum value (exclusive)
     * @return A random number between 0 and max-1
     */
    function _generateRandomNumber(uint256 max) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            raffles[raffleId].participants.length
        ))) % max;
    }
    
    /**
     * @dev Get current raffle details
     * @return id Raffle ID
     * @return _ticketPrice Ticket price
     * @return participantCount Number of participants
     * @return potSize Total pot size
     * @return state Current state
     * @return winner Winner address (if drawn)
     */
    function getCurrentRaffle() external view returns (
        uint256 id,
        uint256 _ticketPrice,
        uint256 participantCount,
        uint256 potSize,
        RaffleState state,
        address winner
    ) {
        require(raffleId > 0, "No raffle created yet");
        RaffleRound memory raffle = raffles[raffleId];
        
        return (
            raffle.id,
            raffle.ticketPrice,
            raffle.participants.length,
            raffle.participants.length * raffle.ticketPrice,
            raffle.state,
            raffle.winner
        );
    }
    
    /**
     * @dev Get raffle details by ID
     * @param _raffleId The raffle ID to query
     * @return id Raffle ID
     * @return _ticketPrice Ticket price
     * @return participantCount Number of participants
     * @return winner Winner address
     * @return prizeAmount Prize amount
     * @return startTime Start time
     * @return endTime End time
     * @return state State
     */
    function getRaffle(uint256 _raffleId) external view returns (
        uint256 id,
        uint256 _ticketPrice,
        uint256 participantCount,
        address winner,
        uint256 prizeAmount,
        uint256 startTime,
        uint256 endTime,
        RaffleState state
    ) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        RaffleRound memory raffle = raffles[_raffleId];
        
        return (
            raffle.id,
            raffle.ticketPrice,
            raffle.participants.length,
            raffle.winner,
            raffle.prizeAmount,
            raffle.startTime,
            raffle.endTime,
            raffle.state
        );
    }
    
    /**
     * @dev Get participant tickets for current raffle
     * @param participant The address to query
     * @return The number of tickets owned by the participant
     */
    function getParticipantTickets(address participant) external view returns (uint256) {
        require(raffleId > 0, "No active raffle");
        return ticketCount[raffleId][participant];
    }
    
    /**
     * @dev Get participant tickets for a specific raffle
     * @param _raffleId The raffle ID
     * @param participant The address to query
     * @return The number of tickets owned by the participant
     */
    function getParticipantTicketsForRaffle(uint256 _raffleId, address participant) external view returns (uint256) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        return ticketCount[_raffleId][participant];
    }
    
    /**
     * @dev Get all participants for current raffle
     * @return Array of participant addresses (includes duplicates for multiple tickets)
     */
    function getCurrentParticipants() external view returns (address[] memory) {
        require(raffleId > 0, "No active raffle");
        return raffles[raffleId].participants;
    }
    
    /**
     * @dev Get the current pot size
     * @return The total amount in the pot
     */
    function getPotSize() external view returns (uint256) {
        require(raffleId > 0, "No active raffle");
        return raffles[raffleId].participants.length * raffles[raffleId].ticketPrice;
    }
    
    /**
     * @dev Update ticket price for future raffles
     * @param newTicketPrice The new ticket price
     */
    function updateTicketPrice(uint256 newTicketPrice) external onlyOwner {
        require(newTicketPrice > 0, "Ticket price must be greater than 0");
        ticketPrice = newTicketPrice;
    }
    
    /**
     * @dev Check if current raffle is open
     * @return True if raffle is open, false otherwise
     */
    function isRaffleOpen() external view returns (bool) {
        if (raffleId == 0) {
            return false;
        }
        return raffles[raffleId].state == RaffleState.OPEN;
    }
    
    /**
     * @dev Get the total number of raffles conducted
     * @return The total raffle count
     */
    function getTotalRaffles() external view returns (uint256) {
        return raffleId;
    }
    
    /**
     * @dev Transfer ownership
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
}
