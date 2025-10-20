// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint256 public entryFee;
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
    mapping(uint256 => mapping(address => uint256)) public participantEntries;

    event RaffleCreated(uint256 indexed raffleId, uint256 entryFee, uint256 startTime);
    event ParticipantEntered(uint256 indexed raffleId, address indexed participant, uint256 entries);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prizeAmount);
    event RaffleClosed(uint256 indexed raffleId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
    }

    function createRaffle() external onlyOwner {
        require(raffleId == 0 || raffles[raffleId].state == RaffleState.COMPLETED, "Previous raffle not completed");
        
        raffleId++;
        
        raffles[raffleId].id = raffleId;
        raffles[raffleId].state = RaffleState.OPEN;
        raffles[raffleId].startTime = block.timestamp;
        raffles[raffleId].prizePool = 0;

        emit RaffleCreated(raffleId, entryFee, block.timestamp);
    }

    function enter() external payable {
        require(raffleId > 0, "No active raffle");
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        require(msg.value == entryFee, "Incorrect entry fee");

        RaffleRound storage raffle = raffles[raffleId];
        
        if (participantEntries[raffleId][msg.sender] == 0) {
            raffle.participants.push(msg.sender);
        }
        
        participantEntries[raffleId][msg.sender]++;
        raffle.prizePool += msg.value;

        emit ParticipantEntered(raffleId, msg.sender, participantEntries[raffleId][msg.sender]);
    }

    function closeRaffle() external onlyOwner {
        require(raffleId > 0, "No active raffle");
        require(raffles[raffleId].state == RaffleState.OPEN, "Raffle is not open");
        
        raffles[raffleId].state = RaffleState.CLOSED;
        raffles[raffleId].endTime = block.timestamp;

        emit RaffleClosed(raffleId);
    }

    function selectWinner() external onlyOwner {
        require(raffleId > 0, "No active raffle");
        RaffleRound storage raffle = raffles[raffleId];
        require(raffle.state == RaffleState.CLOSED, "Raffle must be closed first");
        require(raffle.participants.length > 0, "No participants in raffle");

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            raffle.participants.length
        ))) % raffle.participants.length;

        address winner = raffle.participants[randomIndex];
        raffle.winner = winner;
        raffle.state = RaffleState.COMPLETED;

        uint256 prizeAmount = raffle.prizePool;

        (bool success, ) = payable(winner).call{value: prizeAmount}("");
        require(success, "Prize transfer failed");

        emit WinnerSelected(raffleId, winner, prizeAmount);
    }

    function getRaffleInfo(uint256 _raffleId) external view returns (
        uint256 id,
        uint256 participantCount,
        address winner,
        uint256 prizePool,
        RaffleState state
    ) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Raffle does not exist");
        RaffleRound memory raffle = raffles[_raffleId];
        return (raffle.id, raffle.participants.length, raffle.winner, raffle.prizePool, raffle.state);
    }

    function getParticipants(uint256 _raffleId) external view returns (address[] memory) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Raffle does not exist");
        return raffles[_raffleId].participants;
    }

    function getParticipantEntries(uint256 _raffleId, address participant) external view returns (uint256) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Raffle does not exist");
        return participantEntries[_raffleId][participant];
    }

    function getCurrentRaffleState() external view returns (RaffleState) {
        require(raffleId > 0, "No raffle created yet");
        return raffles[raffleId].state;
    }

    function updateEntryFee(uint256 newFee) external onlyOwner {
        require(raffleId == 0 || raffles[raffleId].state == RaffleState.COMPLETED, "Cannot change fee during active raffle");
        require(newFee > 0, "Entry fee must be greater than 0");
        entryFee = newFee;
    }
}
