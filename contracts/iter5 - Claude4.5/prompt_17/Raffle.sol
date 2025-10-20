// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint256 public ticketPrice;
    uint256 public raffleId;
    
    enum RaffleState { OPEN, CLOSED, FINISHED }
    
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
    mapping(uint256 => mapping(address => uint256)) public participantTickets;
    
    event RaffleCreated(uint256 indexed raffleId, uint256 ticketPrice, uint256 startTime);
    event TicketPurchased(uint256 indexed raffleId, address indexed participant, uint256 numberOfTickets);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prizeAmount);
    event RaffleClosed(uint256 indexed raffleId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _ticketPrice) {
        require(_ticketPrice > 0, "Ticket price must be greater than zero");
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }
    
    function createRaffle() external onlyOwner {
        raffleId++;
        
        raffles[raffleId].id = raffleId;
        raffles[raffleId].state = RaffleState.OPEN;
        raffles[raffleId].startTime = block.timestamp;
        
        emit RaffleCreated(raffleId, ticketPrice, block.timestamp);
    }
    
    function buyTickets(uint256 _numberOfTickets) external payable {
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        require(_numberOfTickets > 0, "Must buy at least one ticket");
        require(msg.value == ticketPrice * _numberOfTickets, "Incorrect payment amount");
        
        RaffleInfo storage currentRaffle = raffles[raffleId];
        
        if (participantTickets[raffleId][msg.sender] == 0) {
            currentRaffle.participants.push(msg.sender);
        }
        
        participantTickets[raffleId][msg.sender] += _numberOfTickets;
        currentRaffle.prizePool += msg.value;
        
        emit TicketPurchased(raffleId, msg.sender, _numberOfTickets);
    }
    
    function closeRaffle() external onlyOwner {
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        
        raffles[raffleId].state = RaffleState.CLOSED;
        raffles[raffleId].endTime = block.timestamp;
        
        emit RaffleClosed(raffleId);
    }
    
    function selectWinner() external onlyOwner {
        RaffleInfo storage currentRaffle = raffles[raffleId];
        
        require(currentRaffle.state == RaffleState.CLOSED, "Raffle must be closed first");
        require(currentRaffle.participants.length > 0, "No participants in raffle");
        
        uint256 totalTickets = 0;
        for (uint256 i = 0; i < currentRaffle.participants.length; i++) {
            totalTickets += participantTickets[raffleId][currentRaffle.participants[i]];
        }
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            currentRaffle.participants.length,
            totalTickets
        ))) % totalTickets;
        
        address winner;
        uint256 ticketCounter = 0;
        
        for (uint256 i = 0; i < currentRaffle.participants.length; i++) {
            address participant = currentRaffle.participants[i];
            uint256 tickets = participantTickets[raffleId][participant];
            
            if (randomNumber < ticketCounter + tickets) {
                winner = participant;
                break;
            }
            
            ticketCounter += tickets;
        }
        
        currentRaffle.winner = winner;
        currentRaffle.state = RaffleState.FINISHED;
        
        uint256 prize = currentRaffle.prizePool;
        
        (bool success, ) = payable(winner).call{value: prize}("");
        require(success, "Transfer to winner failed");
        
        emit WinnerSelected(raffleId, winner, prize);
    }
    
    function getCurrentRaffleInfo() external view returns (
        uint256 id,
        uint256 prizePool,
        uint256 participantCount,
        RaffleState state,
        address winner
    ) {
        RaffleInfo memory currentRaffle = raffles[raffleId];
        
        return (
            currentRaffle.id,
            currentRaffle.prizePool,
            currentRaffle.participants.length,
            currentRaffle.state,
            currentRaffle.winner
        );
    }
    
    function getRaffleParticipants(uint256 _raffleId) external view returns (address[] memory) {
        return raffles[_raffleId].participants;
    }
    
    function getMyTickets(uint256 _raffleId) external view returns (uint256) {
        return participantTickets[_raffleId][msg.sender];
    }
    
    function updateTicketPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Ticket price must be greater than zero");
        require(raffles[raffleId].state != RaffleState.OPEN, "Cannot change price during active raffle");
        
        ticketPrice = _newPrice;
    }
}
