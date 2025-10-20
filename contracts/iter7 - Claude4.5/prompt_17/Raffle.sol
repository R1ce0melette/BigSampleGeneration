// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Raffle
 * @dev An on-chain raffle where participants pay to enter and one random winner gets the pot
 */
contract Raffle {
    address public owner;
    uint256 public entryFee;
    uint256 public raffleId;
    
    // Raffle states
    enum RaffleState {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    
    // Current raffle information
    RaffleState public state;
    address[] public participants;
    mapping(address => uint256) public participantEntryCount;
    uint256 public prizePool;
    address public lastWinner;
    uint256 public lastPrize;
    
    // Events
    event RaffleStarted(uint256 indexed raffleId, uint256 entryFee, uint256 timestamp);
    event EntryPurchased(uint256 indexed raffleId, address indexed participant, uint256 entryCount);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prize, uint256 timestamp);
    event RaffleClosed(uint256 indexed raffleId);
    event EntryFeeUpdated(uint256 oldFee, uint256 newFee);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier raffleOpen() {
        require(state == RaffleState.OPEN, "Raffle is not open");
        _;
    }
    
    /**
     * @dev Constructor to initialize the raffle
     * @param _entryFee The entry fee for the raffle in wei
     */
    constructor(uint256 _entryFee) {
        require(_entryFee > 0, "Entry fee must be greater than 0");
        owner = msg.sender;
        entryFee = _entryFee;
        state = RaffleState.OPEN;
        raffleId = 1;
        
        emit RaffleStarted(raffleId, entryFee, block.timestamp);
    }
    
    /**
     * @dev Enter the raffle
     * Requirements:
     * - Raffle must be open
     * - Correct entry fee must be paid
     */
    function enter() external payable raffleOpen {
        require(msg.value == entryFee, "Incorrect entry fee");
        
        // Add participant
        participants.push(msg.sender);
        participantEntryCount[msg.sender]++;
        prizePool += msg.value;
        
        emit EntryPurchased(raffleId, msg.sender, participantEntryCount[msg.sender]);
    }
    
    /**
     * @dev Enter the raffle multiple times
     * @param entries The number of entries to purchase
     */
    function enterMultiple(uint256 entries) external payable raffleOpen {
        require(entries > 0, "Must enter at least once");
        require(msg.value == entryFee * entries, "Incorrect entry fee");
        
        // Add participant multiple times
        for (uint256 i = 0; i < entries; i++) {
            participants.push(msg.sender);
        }
        
        participantEntryCount[msg.sender] += entries;
        prizePool += msg.value;
        
        emit EntryPurchased(raffleId, msg.sender, participantEntryCount[msg.sender]);
    }
    
    /**
     * @dev Select a random winner and distribute the prize
     * Requirements:
     * - Only owner can select winner
     * - Raffle must be open
     * - At least one participant must have entered
     */
    function selectWinner() external onlyOwner {
        require(state == RaffleState.OPEN, "Raffle is not open");
        require(participants.length > 0, "No participants in raffle");
        
        state = RaffleState.CALCULATING_WINNER;
        
        // Generate pseudo-random number
        uint256 randomIndex = _generateRandomNumber() % participants.length;
        address winner = participants[randomIndex];
        
        uint256 prize = prizePool;
        
        // Reset raffle
        lastWinner = winner;
        lastPrize = prize;
        
        // Transfer prize to winner
        (bool success, ) = winner.call{value: prize}("");
        require(success, "Prize transfer failed");
        
        emit WinnerSelected(raffleId, winner, prize, block.timestamp);
        
        // Start new raffle
        _resetRaffle();
    }
    
    /**
     * @dev Generate a pseudo-random number
     * Note: This is not truly random and should not be used in production
     * @return A pseudo-random number
     */
    function _generateRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            participants.length,
            msg.sender
        )));
    }
    
    /**
     * @dev Reset raffle for the next round
     */
    function _resetRaffle() private {
        // Clear participants
        for (uint256 i = 0; i < participants.length; i++) {
            delete participantEntryCount[participants[i]];
        }
        delete participants;
        
        prizePool = 0;
        raffleId++;
        state = RaffleState.OPEN;
        
        emit RaffleStarted(raffleId, entryFee, block.timestamp);
    }
    
    /**
     * @dev Close the raffle without selecting a winner (refunds all participants)
     * Requirements:
     * - Only owner can close raffle
     * - Raffle must be open
     */
    function closeAndRefund() external onlyOwner {
        require(state == RaffleState.OPEN, "Raffle is not open");
        
        state = RaffleState.CLOSED;
        
        // Refund all participants
        uint256 refundAmount = entryFee;
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            (bool success, ) = participant.call{value: refundAmount}("");
            require(success, "Refund transfer failed");
        }
        
        emit RaffleClosed(raffleId);
        
        // Reset raffle
        _resetRaffle();
    }
    
    /**
     * @dev Get the number of participants
     * @return The number of entries (participants may appear multiple times)
     */
    function getParticipantCount() external view returns (uint256) {
        return participants.length;
    }
    
    /**
     * @dev Get all participants
     * @return Array of participant addresses
     */
    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
    
    /**
     * @dev Get unique participants count
     * @return The number of unique participants
     */
    function getUniqueParticipantCount() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < participants.length; i++) {
            if (participantEntryCount[participants[i]] > 0) {
                bool isUnique = true;
                for (uint256 j = 0; j < i; j++) {
                    if (participants[i] == participants[j]) {
                        isUnique = false;
                        break;
                    }
                }
                if (isUnique) {
                    count++;
                }
            }
        }
        
        return count;
    }
    
    /**
     * @dev Get raffle information
     * @return currentRaffleId Current raffle ID
     * @return currentState Current raffle state
     * @return currentEntryFee Entry fee
     * @return currentPrizePool Current prize pool
     * @return participantCount Number of entries
     */
    function getRaffleInfo() external view returns (
        uint256 currentRaffleId,
        RaffleState currentState,
        uint256 currentEntryFee,
        uint256 currentPrizePool,
        uint256 participantCount
    ) {
        return (
            raffleId,
            state,
            entryFee,
            prizePool,
            participants.length
        );
    }
    
    /**
     * @dev Get last raffle results
     * @return winner Address of last winner
     * @return prize Last prize amount
     */
    function getLastRaffleResult() external view returns (address winner, uint256 prize) {
        return (lastWinner, lastPrize);
    }
    
    /**
     * @dev Get caller's entry count
     * @return The number of entries for the caller
     */
    function getMyEntries() external view returns (uint256) {
        return participantEntryCount[msg.sender];
    }
    
    /**
     * @dev Update entry fee (only owner, only when raffle is closed)
     * @param newFee The new entry fee
     */
    function setEntryFee(uint256 newFee) external onlyOwner {
        require(newFee > 0, "Entry fee must be greater than 0");
        require(participants.length == 0, "Cannot change fee while raffle has participants");
        
        uint256 oldFee = entryFee;
        entryFee = newFee;
        
        emit EntryFeeUpdated(oldFee, newFee);
    }
    
    /**
     * @dev Emergency withdraw (only owner, only if no participants)
     */
    function emergencyWithdraw() external onlyOwner {
        require(participants.length == 0, "Cannot withdraw while raffle has participants");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
