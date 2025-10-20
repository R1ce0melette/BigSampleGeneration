// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint256 public ticketPrice;
    uint256 public raffleId;
    
    enum RaffleState { OPEN, CLOSED, COMPLETED }
    
    struct RaffleRound {
        uint256 id;
        address[] participants;
        address winner;
        uint256 prizePool;
        RaffleState state;
        uint256 startTime;
        uint256 endTime;
    }
    
    mapping(uint256 => RaffleRound) public raffles;
    mapping(uint256 => mapping(address => uint256)) public ticketCount;
    
    event RaffleStarted(uint256 indexed raffleId, uint256 ticketPrice, uint256 startTime);
    event TicketPurchased(uint256 indexed raffleId, address indexed participant, uint256 ticketCount);
    event RaffleClosed(uint256 indexed raffleId, uint256 totalParticipants, uint256 prizePool);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prize);
    event PrizeTransferred(uint256 indexed raffleId, address indexed winner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }
    
    function startRaffle() external onlyOwner {
        require(raffles[raffleId].state != RaffleState.OPEN, "Raffle is already active");
        
        raffleId++;
        
        raffles[raffleId].id = raffleId;
        raffles[raffleId].state = RaffleState.OPEN;
        raffles[raffleId].startTime = block.timestamp;
        raffles[raffleId].prizePool = 0;
        
        emit RaffleStarted(raffleId, ticketPrice, block.timestamp);
    }
    
    function buyTicket(uint256 _numberOfTickets) external payable {
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        require(_numberOfTickets > 0, "Must buy at least one ticket");
        require(msg.value == ticketPrice * _numberOfTickets, "Incorrect payment amount");
        
        RaffleRound storage currentRaffle = raffles[raffleId];
        
        // Add tickets for the participant
        for (uint256 i = 0; i < _numberOfTickets; i++) {
            currentRaffle.participants.push(msg.sender);
        }
        
        ticketCount[raffleId][msg.sender] += _numberOfTickets;
        currentRaffle.prizePool += msg.value;
        
        emit TicketPurchased(raffleId, msg.sender, _numberOfTickets);
    }
    
    function closeRaffle() external onlyOwner {
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        
        RaffleRound storage currentRaffle = raffles[raffleId];
        currentRaffle.state = RaffleState.CLOSED;
        currentRaffle.endTime = block.timestamp;
        
        emit RaffleClosed(raffleId, currentRaffle.participants.length, currentRaffle.prizePool);
    }
    
    function selectWinner() external onlyOwner {
        require(raffles[raffleId].state == RaffleState.CLOSED, "Raffle is not closed");
        
        RaffleRound storage currentRaffle = raffles[raffleId];
        require(currentRaffle.participants.length > 0, "No participants in raffle");
        
        // Generate pseudo-random number
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            currentRaffle.participants.length,
            msg.sender
        ))) % currentRaffle.participants.length;
        
        address winner = currentRaffle.participants[randomIndex];
        currentRaffle.winner = winner;
        currentRaffle.state = RaffleState.COMPLETED;
        
        emit WinnerSelected(raffleId, winner, currentRaffle.prizePool);
        
        // Transfer prize to winner
        uint256 prize = currentRaffle.prizePool;
        (bool success, ) = payable(winner).call{value: prize}("");
        require(success, "Prize transfer failed");
        
        emit PrizeTransferred(raffleId, winner, prize);
    }
    
    function getRaffleInfo(uint256 _raffleId) external view returns (
        uint256 id,
        uint256 participantCount,
        address winner,
        uint256 prizePool,
        RaffleState state,
        uint256 startTime,
        uint256 endTime
    ) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        RaffleRound memory raffle = raffles[_raffleId];
        
        return (
            raffle.id,
            raffle.participants.length,
            raffle.winner,
            raffle.prizePool,
            raffle.state,
            raffle.startTime,
            raffle.endTime
        );
    }
    
    function getParticipants(uint256 _raffleId) external view returns (address[] memory) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        return raffles[_raffleId].participants;
    }
    
    function getUserTicketCount(uint256 _raffleId, address _user) external view returns (uint256) {
        return ticketCount[_raffleId][_user];
    }
    
    function getCurrentRaffleState() external view returns (RaffleState) {
        if (raffleId == 0) {
            return RaffleState.CLOSED;
        }
        return raffles[raffleId].state;
    }
    
    function updateTicketPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Ticket price must be greater than 0");
        require(raffles[raffleId].state != RaffleState.OPEN, "Cannot change price during active raffle");
        ticketPrice = _newPrice;
    }
}
