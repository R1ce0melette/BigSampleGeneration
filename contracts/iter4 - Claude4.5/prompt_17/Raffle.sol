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
    
    enum RaffleState { OPEN, CLOSED, COMPLETE }
    
    struct RaffleInfo {
        uint256 id;
        uint256 prizePool;
        address[] participants;
        address winner;
        RaffleState state;
        uint256 startTime;
        uint256 endTime;
    }
    
    mapping(uint256 => RaffleInfo) public raffles;
    mapping(uint256 => mapping(address => uint256)) public ticketCount;
    
    // Events
    event RaffleStarted(uint256 indexed raffleId, uint256 ticketPrice, uint256 startTime);
    event TicketPurchased(uint256 indexed raffleId, address indexed participant, uint256 ticketCount);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prize);
    event RaffleClosed(uint256 indexed raffleId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the raffle contract
     * @param _ticketPrice The price of each ticket in wei
     */
    constructor(uint256 _ticketPrice) {
        require(_ticketPrice > 0, "Ticket price must be greater than 0");
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }
    
    /**
     * @dev Starts a new raffle
     */
    function startRaffle() external onlyOwner {
        if (raffleId > 0) {
            require(raffles[raffleId].state != RaffleState.OPEN, "Previous raffle still open");
        }
        
        raffleId++;
        
        raffles[raffleId].id = raffleId;
        raffles[raffleId].state = RaffleState.OPEN;
        raffles[raffleId].startTime = block.timestamp;
        
        emit RaffleStarted(raffleId, ticketPrice, block.timestamp);
    }
    
    /**
     * @dev Allows users to buy tickets for the current raffle
     * @param _ticketAmount The number of tickets to purchase
     */
    function buyTickets(uint256 _ticketAmount) external payable {
        require(raffleId > 0, "No active raffle");
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        require(_ticketAmount > 0, "Must buy at least one ticket");
        require(msg.value == ticketPrice * _ticketAmount, "Incorrect payment amount");
        
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Add participant entries based on ticket count
        for (uint256 i = 0; i < _ticketAmount; i++) {
            raffle.participants.push(msg.sender);
        }
        
        ticketCount[raffleId][msg.sender] += _ticketAmount;
        raffle.prizePool += msg.value;
        
        emit TicketPurchased(raffleId, msg.sender, _ticketAmount);
    }
    
    /**
     * @dev Closes the current raffle (no more entries allowed)
     */
    function closeRaffle() external onlyOwner {
        require(raffleId > 0, "No active raffle");
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        
        raffles[raffleId].state = RaffleState.CLOSED;
        raffles[raffleId].endTime = block.timestamp;
        
        emit RaffleClosed(raffleId);
    }
    
    /**
     * @dev Selects a random winner and distributes the prize
     */
    function selectWinner() external onlyOwner {
        require(raffleId > 0, "No active raffle");
        require(raffles[raffleId].state == RaffleState.CLOSED, "Raffle must be closed first");
        
        RaffleInfo storage raffle = raffles[raffleId];
        require(raffle.participants.length > 0, "No participants in raffle");
        
        // Generate pseudo-random number
        uint256 randomIndex = _generateRandomNumber(raffle.participants.length);
        address winner = raffle.participants[randomIndex];
        
        raffle.winner = winner;
        raffle.state = RaffleState.COMPLETE;
        
        uint256 prize = raffle.prizePool;
        
        // Transfer prize to winner
        (bool success, ) = payable(winner).call{value: prize}("");
        require(success, "Prize transfer failed");
        
        emit WinnerSelected(raffleId, winner, prize);
    }
    
    /**
     * @dev Generates a pseudo-random number (not suitable for high-value raffles)
     * @param _max The maximum value (exclusive)
     * @return A random number between 0 and _max-1
     */
    function _generateRandomNumber(uint256 _max) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            raffles[raffleId].participants.length
        ))) % _max;
    }
    
    /**
     * @dev Returns the current raffle information
     * @return id The raffle ID
     * @return prizePool The current prize pool
     * @return participantCount The number of participants
     * @return winner The winner's address (if selected)
     * @return state The raffle state
     * @return startTime When the raffle started
     * @return endTime When the raffle ended
     */
    function getCurrentRaffle() external view returns (
        uint256 id,
        uint256 prizePool,
        uint256 participantCount,
        address winner,
        RaffleState state,
        uint256 startTime,
        uint256 endTime
    ) {
        require(raffleId > 0, "No raffle exists");
        
        RaffleInfo storage raffle = raffles[raffleId];
        
        return (
            raffle.id,
            raffle.prizePool,
            raffle.participants.length,
            raffle.winner,
            raffle.state,
            raffle.startTime,
            raffle.endTime
        );
    }
    
    /**
     * @dev Returns information about a specific raffle
     * @param _raffleId The ID of the raffle
     * @return id The raffle ID
     * @return prizePool The prize pool
     * @return participantCount The number of participants
     * @return winner The winner's address (if selected)
     * @return state The raffle state
     * @return startTime When the raffle started
     * @return endTime When the raffle ended
     */
    function getRaffleInfo(uint256 _raffleId) external view returns (
        uint256 id,
        uint256 prizePool,
        uint256 participantCount,
        address winner,
        RaffleState state,
        uint256 startTime,
        uint256 endTime
    ) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        
        RaffleInfo storage raffle = raffles[_raffleId];
        
        return (
            raffle.id,
            raffle.prizePool,
            raffle.participants.length,
            raffle.winner,
            raffle.state,
            raffle.startTime,
            raffle.endTime
        );
    }
    
    /**
     * @dev Returns the number of tickets a user has for the current raffle
     * @param _user The address of the user
     * @return The number of tickets
     */
    function getUserTicketCount(address _user) external view returns (uint256) {
        require(raffleId > 0, "No raffle exists");
        return ticketCount[raffleId][_user];
    }
    
    /**
     * @dev Returns the number of tickets the caller has for the current raffle
     * @return The number of tickets
     */
    function getMyTicketCount() external view returns (uint256) {
        require(raffleId > 0, "No raffle exists");
        return ticketCount[raffleId][msg.sender];
    }
    
    /**
     * @dev Returns all participants in the current raffle
     * @return Array of participant addresses (with duplicates for multiple tickets)
     */
    function getParticipants() external view returns (address[] memory) {
        require(raffleId > 0, "No raffle exists");
        return raffles[raffleId].participants;
    }
    
    /**
     * @dev Returns the number of participants in the current raffle
     * @return The participant count
     */
    function getParticipantCount() external view returns (uint256) {
        require(raffleId > 0, "No raffle exists");
        return raffles[raffleId].participants.length;
    }
    
    /**
     * @dev Allows the owner to update the ticket price (only when no active raffle)
     * @param _newPrice The new ticket price
     */
    function updateTicketPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Ticket price must be greater than 0");
        
        if (raffleId > 0) {
            require(raffles[raffleId].state != RaffleState.OPEN, "Cannot change price during active raffle");
        }
        
        ticketPrice = _newPrice;
    }
    
    /**
     * @dev Returns the current raffle state as a string
     * @return The state as a string
     */
    function getRaffleStateString() external view returns (string memory) {
        require(raffleId > 0, "No raffle exists");
        
        RaffleState state = raffles[raffleId].state;
        
        if (state == RaffleState.OPEN) return "OPEN";
        if (state == RaffleState.CLOSED) return "CLOSED";
        if (state == RaffleState.COMPLETE) return "COMPLETE";
        
        return "UNKNOWN";
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
