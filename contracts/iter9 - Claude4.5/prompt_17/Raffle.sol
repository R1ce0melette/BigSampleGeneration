// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint256 public entryFee;
    uint256 public raffleId;
    
    struct RaffleRound {
        uint256 id;
        address[] participants;
        address winner;
        uint256 prizePool;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isFinalized;
    }
    
    mapping(uint256 => RaffleRound) public raffles;
    mapping(uint256 => mapping(address => uint256)) public participantEntries;
    
    // Events
    event RaffleStarted(uint256 indexed raffleId, uint256 entryFee, uint256 endTime);
    event EntryPurchased(uint256 indexed raffleId, address indexed participant, uint256 entries);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prizeAmount);
    event RaffleFinalized(uint256 indexed raffleId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _entryFee) {
        require(_entryFee > 0, "Entry fee must be greater than 0");
        owner = msg.sender;
        entryFee = _entryFee;
    }
    
    /**
     * @dev Start a new raffle
     * @param _duration Duration of the raffle in seconds
     */
    function startRaffle(uint256 _duration) external onlyOwner {
        require(_duration > 0, "Duration must be greater than 0");
        
        if (raffleId > 0) {
            require(raffles[raffleId].isFinalized, "Previous raffle must be finalized");
        }
        
        raffleId++;
        
        raffles[raffleId].id = raffleId;
        raffles[raffleId].startTime = block.timestamp;
        raffles[raffleId].endTime = block.timestamp + _duration;
        raffles[raffleId].isActive = true;
        raffles[raffleId].isFinalized = false;
        
        emit RaffleStarted(raffleId, entryFee, raffles[raffleId].endTime);
    }
    
    /**
     * @dev Enter the current raffle
     */
    function enterRaffle() external payable {
        require(raffleId > 0, "No active raffle");
        require(raffles[raffleId].isActive, "Raffle is not active");
        require(block.timestamp < raffles[raffleId].endTime, "Raffle has ended");
        require(msg.value > 0 && msg.value % entryFee == 0, "Invalid entry fee");
        
        uint256 entries = msg.value / entryFee;
        
        raffles[raffleId].prizePool += msg.value;
        
        // Add participant entries
        if (participantEntries[raffleId][msg.sender] == 0) {
            // First time entering this raffle
            for (uint256 i = 0; i < entries; i++) {
                raffles[raffleId].participants.push(msg.sender);
            }
        } else {
            // Already entered, add more entries
            for (uint256 i = 0; i < entries; i++) {
                raffles[raffleId].participants.push(msg.sender);
            }
        }
        
        participantEntries[raffleId][msg.sender] += entries;
        
        emit EntryPurchased(raffleId, msg.sender, entries);
    }
    
    /**
     * @dev Select winner and distribute prize
     */
    function selectWinner() external onlyOwner {
        require(raffleId > 0, "No raffle exists");
        require(raffles[raffleId].isActive, "Raffle is not active");
        require(block.timestamp >= raffles[raffleId].endTime, "Raffle has not ended yet");
        require(raffles[raffleId].participants.length > 0, "No participants");
        require(!raffles[raffleId].isFinalized, "Raffle already finalized");
        
        RaffleRound storage raffle = raffles[raffleId];
        
        // Generate pseudo-random number
        uint256 randomIndex = _generateRandomNumber(raffle.participants.length);
        address winner = raffle.participants[randomIndex];
        
        raffle.winner = winner;
        raffle.isActive = false;
        raffle.isFinalized = true;
        
        uint256 prizeAmount = raffle.prizePool;
        
        // Transfer prize to winner
        (bool success, ) = payable(winner).call{value: prizeAmount}("");
        require(success, "Transfer to winner failed");
        
        emit WinnerSelected(raffleId, winner, prizeAmount);
        emit RaffleFinalized(raffleId);
    }
    
    /**
     * @dev Generate a pseudo-random number
     * @param _max Maximum value (exclusive)
     * @return Random number between 0 and _max-1
     */
    function _generateRandomNumber(uint256 _max) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    raffles[raffleId].participants.length,
                    raffles[raffleId].prizePool
                )
            )
        ) % _max;
    }
    
    /**
     * @dev Get raffle details
     * @param _raffleId The ID of the raffle
     * @return id The raffle ID
     * @return participantCount Number of participants
     * @return winner The winner address
     * @return prizePool The prize pool amount
     * @return startTime The start timestamp
     * @return endTime The end timestamp
     * @return isActive Whether the raffle is active
     * @return isFinalized Whether the raffle is finalized
     */
    function getRaffleDetails(uint256 _raffleId) external view returns (
        uint256 id,
        uint256 participantCount,
        address winner,
        uint256 prizePool,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool isFinalized
    ) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        
        RaffleRound storage raffle = raffles[_raffleId];
        
        return (
            raffle.id,
            raffle.participants.length,
            raffle.winner,
            raffle.prizePool,
            raffle.startTime,
            raffle.endTime,
            raffle.isActive,
            raffle.isFinalized
        );
    }
    
    /**
     * @dev Get participant entries for a raffle
     * @param _raffleId The ID of the raffle
     * @param _participant The participant address
     * @return The number of entries
     */
    function getParticipantEntries(uint256 _raffleId, address _participant) external view returns (uint256) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        
        return participantEntries[_raffleId][_participant];
    }
    
    /**
     * @dev Get current raffle status
     * @return currentRaffleId The current raffle ID
     * @return isActive Whether the current raffle is active
     * @return participantCount Number of participants
     * @return prizePool Current prize pool
     * @return timeRemaining Time remaining in seconds (0 if ended)
     */
    function getCurrentRaffleStatus() external view returns (
        uint256 currentRaffleId,
        bool isActive,
        uint256 participantCount,
        uint256 prizePool,
        uint256 timeRemaining
    ) {
        if (raffleId == 0) {
            return (0, false, 0, 0, 0);
        }
        
        RaffleRound storage raffle = raffles[raffleId];
        
        uint256 remaining = 0;
        if (raffle.isActive && block.timestamp < raffle.endTime) {
            remaining = raffle.endTime - block.timestamp;
        }
        
        return (
            raffleId,
            raffle.isActive,
            raffle.participants.length,
            raffle.prizePool,
            remaining
        );
    }
    
    /**
     * @dev Update entry fee for future raffles
     * @param _newEntryFee The new entry fee
     */
    function updateEntryFee(uint256 _newEntryFee) external onlyOwner {
        require(_newEntryFee > 0, "Entry fee must be greater than 0");
        
        entryFee = _newEntryFee;
    }
    
    /**
     * @dev Get all participants for a raffle (use with caution for large arrays)
     * @param _raffleId The ID of the raffle
     * @return Array of participant addresses
     */
    function getParticipants(uint256 _raffleId) external view returns (address[] memory) {
        require(_raffleId > 0 && _raffleId <= raffleId, "Invalid raffle ID");
        
        return raffles[_raffleId].participants;
    }
}
