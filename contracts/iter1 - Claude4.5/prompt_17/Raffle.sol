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
    
    enum RaffleState {
        OPEN,
        CLOSED,
        COMPLETED
    }
    
    struct RaffleRound {
        uint256 id;
        uint256 ticketPrice;
        uint256 startTime;
        uint256 endTime;
        address[] participants;
        mapping(address => uint256) ticketCount;
        address winner;
        uint256 prizeAmount;
        RaffleState state;
    }
    
    mapping(uint256 => RaffleRound) public raffles;
    RaffleRound private currentRaffle;
    
    event RaffleStarted(uint256 indexed raffleId, uint256 ticketPrice, uint256 endTime);
    event TicketPurchased(uint256 indexed raffleId, address indexed participant, uint256 ticketCount);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prizeAmount);
    event RaffleClosed(uint256 indexed raffleId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Start a new raffle
     * @param _ticketPrice Price per ticket in wei
     * @param durationInMinutes How long the raffle will run
     */
    function startRaffle(uint256 _ticketPrice, uint256 durationInMinutes) external onlyOwner {
        require(_ticketPrice > 0, "Ticket price must be greater than 0");
        require(durationInMinutes > 0, "Duration must be greater than 0");
        require(
            raffleId == 0 || raffles[raffleId].state == RaffleState.COMPLETED,
            "Previous raffle not completed"
        );
        
        raffleId++;
        
        RaffleRound storage newRaffle = raffles[raffleId];
        newRaffle.id = raffleId;
        newRaffle.ticketPrice = _ticketPrice;
        newRaffle.startTime = block.timestamp;
        newRaffle.endTime = block.timestamp + (durationInMinutes * 1 minutes);
        newRaffle.state = RaffleState.OPEN;
        
        emit RaffleStarted(raffleId, _ticketPrice, newRaffle.endTime);
    }
    
    /**
     * @dev Purchase raffle tickets
     * @param numberOfTickets Number of tickets to purchase
     */
    function buyTickets(uint256 numberOfTickets) external payable {
        require(raffleId > 0, "No active raffle");
        RaffleRound storage raffle = raffles[raffleId];
        
        require(raffle.state == RaffleState.OPEN, "Raffle is not open");
        require(block.timestamp < raffle.endTime, "Raffle has ended");
        require(numberOfTickets > 0, "Must buy at least one ticket");
        require(
            msg.value == raffle.ticketPrice * numberOfTickets,
            "Incorrect payment amount"
        );
        
        // Add participant if first time
        if (raffle.ticketCount[msg.sender] == 0) {
            raffle.participants.push(msg.sender);
        }
        
        raffle.ticketCount[msg.sender] += numberOfTickets;
        
        emit TicketPurchased(raffleId, msg.sender, numberOfTickets);
    }
    
    /**
     * @dev Close the raffle and select a winner
     */
    function closeRaffle() external onlyOwner {
        require(raffleId > 0, "No active raffle");
        RaffleRound storage raffle = raffles[raffleId];
        
        require(raffle.state == RaffleState.OPEN, "Raffle is not open");
        require(block.timestamp >= raffle.endTime, "Raffle has not ended yet");
        
        raffle.state = RaffleState.CLOSED;
        
        emit RaffleClosed(raffleId);
    }
    
    /**
     * @dev Select winner and distribute prize
     */
    function selectWinner() external onlyOwner {
        require(raffleId > 0, "No active raffle");
        RaffleRound storage raffle = raffles[raffleId];
        
        require(raffle.state == RaffleState.CLOSED, "Raffle must be closed first");
        require(raffle.participants.length > 0, "No participants");
        
        // Calculate total tickets
        uint256 totalTickets = 0;
        for (uint256 i = 0; i < raffle.participants.length; i++) {
            totalTickets += raffle.ticketCount[raffle.participants[i]];
        }
        
        // Generate pseudo-random number
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    raffle.participants.length,
                    totalTickets
                )
            )
        ) % totalTickets;
        
        // Find winner based on ticket distribution
        uint256 counter = 0;
        address winner;
        
        for (uint256 i = 0; i < raffle.participants.length; i++) {
            counter += raffle.ticketCount[raffle.participants[i]];
            if (randomNumber < counter) {
                winner = raffle.participants[i];
                break;
            }
        }
        
        raffle.winner = winner;
        raffle.prizeAmount = raffle.ticketPrice * totalTickets;
        raffle.state = RaffleState.COMPLETED;
        
        // Transfer prize to winner
        (bool success, ) = payable(winner).call{value: raffle.prizeAmount}("");
        require(success, "Transfer to winner failed");
        
        emit WinnerSelected(raffleId, winner, raffle.prizeAmount);
    }
    
    /**
     * @dev Get current raffle details
     * @return id Raffle ID
     * @return _ticketPrice Price per ticket
     * @return startTime Start timestamp
     * @return endTime End timestamp
     * @return participantCount Number of participants
     * @return state Current state
     * @return winner Winner address (if selected)
     * @return prizeAmount Prize amount (if completed)
     */
    function getCurrentRaffleDetails() external view returns (
        uint256 id,
        uint256 _ticketPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 participantCount,
        RaffleState state,
        address winner,
        uint256 prizeAmount
    ) {
        require(raffleId > 0, "No raffle exists");
        RaffleRound storage raffle = raffles[raffleId];
        
        return (
            raffle.id,
            raffle.ticketPrice,
            raffle.startTime,
            raffle.endTime,
            raffle.participants.length,
            raffle.state,
            raffle.winner,
            raffle.prizeAmount
        );
    }
    
    /**
     * @dev Get participants in current raffle
     * @return Array of participant addresses
     */
    function getCurrentParticipants() external view returns (address[] memory) {
        require(raffleId > 0, "No raffle exists");
        return raffles[raffleId].participants;
    }
    
    /**
     * @dev Get ticket count for an address in current raffle
     * @param participant The address to check
     * @return Number of tickets
     */
    function getTicketCount(address participant) external view returns (uint256) {
        require(raffleId > 0, "No raffle exists");
        return raffles[raffleId].ticketCount[participant];
    }
    
    /**
     * @dev Get total tickets sold in current raffle
     * @return Total number of tickets
     */
    function getTotalTickets() external view returns (uint256) {
        require(raffleId > 0, "No raffle exists");
        RaffleRound storage raffle = raffles[raffleId];
        
        uint256 total = 0;
        for (uint256 i = 0; i < raffle.participants.length; i++) {
            total += raffle.ticketCount[raffle.participants[i]];
        }
        
        return total;
    }
    
    /**
     * @dev Get current prize pool
     * @return The current prize amount
     */
    function getCurrentPrizePool() external view returns (uint256) {
        require(raffleId > 0, "No raffle exists");
        RaffleRound storage raffle = raffles[raffleId];
        
        uint256 totalTickets = 0;
        for (uint256 i = 0; i < raffle.participants.length; i++) {
            totalTickets += raffle.ticketCount[raffle.participants[i]];
        }
        
        return raffle.ticketPrice * totalTickets;
    }
    
    /**
     * @dev Get time remaining in current raffle
     * @return Time remaining in seconds (0 if ended)
     */
    function getTimeRemaining() external view returns (uint256) {
        require(raffleId > 0, "No raffle exists");
        RaffleRound storage raffle = raffles[raffleId];
        
        if (block.timestamp >= raffle.endTime) {
            return 0;
        }
        
        return raffle.endTime - block.timestamp;
    }
    
    /**
     * @dev Get details of a specific raffle
     * @param _raffleId The raffle ID to query
     * @return id Raffle ID
     * @return _ticketPrice Price per ticket
     * @return startTime Start timestamp
     * @return endTime End timestamp
     * @return participantCount Number of participants
     * @return state Current state
     * @return winner Winner address (if selected)
     * @return prizeAmount Prize amount (if completed)
     */
    function getRaffleDetails(uint256 _raffleId) external view returns (
        uint256 id,
        uint256 _ticketPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 participantCount,
        RaffleState state,
        address winner,
        uint256 prizeAmount
    ) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        RaffleRound storage raffle = raffles[_raffleId];
        
        return (
            raffle.id,
            raffle.ticketPrice,
            raffle.startTime,
            raffle.endTime,
            raffle.participants.length,
            raffle.state,
            raffle.winner,
            raffle.prizeAmount
        );
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
