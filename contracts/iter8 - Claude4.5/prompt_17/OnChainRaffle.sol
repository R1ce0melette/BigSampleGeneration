// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OnChainRaffle
 * @dev On-chain raffle where participants pay to enter and one random winner gets the pot
 */
contract OnChainRaffle {
    // Raffle status enum
    enum RaffleStatus {
        Open,
        Closed,
        Drawn
    }

    // Raffle structure
    struct Raffle {
        uint256 id;
        uint256 entryFee;
        uint256 prizePool;
        address[] participants;
        address winner;
        RaffleStatus status;
        uint256 createdAt;
        uint256 closedAt;
        uint256 drawnAt;
        uint256 maxParticipants;
    }

    // Participant statistics
    struct ParticipantStats {
        uint256 totalEntries;
        uint256 totalSpent;
        uint256 rafflesWon;
        uint256 totalWinnings;
    }

    // State variables
    address public owner;
    uint256 private raffleCounter;
    uint256 public ownerFeePercent; // Fee in basis points (e.g., 100 = 1%)
    
    mapping(uint256 => Raffle) private raffles;
    mapping(uint256 => mapping(address => uint256)) private participantEntryCount;
    mapping(address => uint256[]) private userRaffleIds;
    mapping(address => ParticipantStats) private participantStats;
    
    uint256[] private allRaffleIds;
    uint256 public activeRaffleId;

    // Events
    event RaffleCreated(uint256 indexed raffleId, uint256 entryFee, uint256 maxParticipants, uint256 timestamp);
    event RaffleEntered(uint256 indexed raffleId, address indexed participant, uint256 entries, uint256 amount);
    event RaffleClosed(uint256 indexed raffleId, uint256 participantCount, uint256 prizePool);
    event WinnerDrawn(uint256 indexed raffleId, address indexed winner, uint256 prize, uint256 timestamp);
    event PrizeWithdrawn(uint256 indexed raffleId, address indexed winner, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier raffleExists(uint256 raffleId) {
        require(raffleId > 0 && raffleId <= raffleCounter, "Raffle does not exist");
        _;
    }

    modifier raffleOpen(uint256 raffleId) {
        require(raffles[raffleId].status == RaffleStatus.Open, "Raffle is not open");
        _;
    }

    modifier raffleClosed(uint256 raffleId) {
        require(raffles[raffleId].status == RaffleStatus.Closed, "Raffle is not closed");
        _;
    }

    constructor(uint256 _ownerFeePercent) {
        require(_ownerFeePercent <= 1000, "Fee cannot exceed 10%");
        owner = msg.sender;
        raffleCounter = 0;
        ownerFeePercent = _ownerFeePercent;
        activeRaffleId = 0;
    }

    /**
     * @dev Create a new raffle
     * @param entryFee Entry fee per ticket
     * @param maxParticipants Maximum number of participants (0 for unlimited)
     * @return raffleId ID of the created raffle
     */
    function createRaffle(uint256 entryFee, uint256 maxParticipants) 
        public 
        onlyOwner 
        returns (uint256) 
    {
        require(entryFee > 0, "Entry fee must be greater than 0");
        require(activeRaffleId == 0, "Close active raffle first");

        raffleCounter++;
        uint256 raffleId = raffleCounter;

        Raffle storage newRaffle = raffles[raffleId];
        newRaffle.id = raffleId;
        newRaffle.entryFee = entryFee;
        newRaffle.prizePool = 0;
        newRaffle.status = RaffleStatus.Open;
        newRaffle.createdAt = block.timestamp;
        newRaffle.maxParticipants = maxParticipants;

        allRaffleIds.push(raffleId);
        activeRaffleId = raffleId;

        emit RaffleCreated(raffleId, entryFee, maxParticipants, block.timestamp);

        return raffleId;
    }

    /**
     * @dev Enter the active raffle with multiple entries
     * @param entries Number of entries to purchase
     */
    function enterRaffle(uint256 entries) public payable {
        require(activeRaffleId > 0, "No active raffle");
        require(entries > 0, "Must enter at least once");
        
        Raffle storage raffle = raffles[activeRaffleId];
        require(raffle.status == RaffleStatus.Open, "Raffle is not open");
        
        uint256 totalCost = raffle.entryFee * entries;
        require(msg.value == totalCost, "Incorrect payment amount");

        if (raffle.maxParticipants > 0) {
            require(
                raffle.participants.length + entries <= raffle.maxParticipants,
                "Exceeds max participants"
            );
        }

        // Add entries for participant
        for (uint256 i = 0; i < entries; i++) {
            raffle.participants.push(msg.sender);
        }

        raffle.prizePool += msg.value;
        participantEntryCount[activeRaffleId][msg.sender] += entries;

        // Update participant stats
        ParticipantStats storage stats = participantStats[msg.sender];
        stats.totalEntries += entries;
        stats.totalSpent += msg.value;

        // Track user's raffles
        if (participantEntryCount[activeRaffleId][msg.sender] == entries) {
            userRaffleIds[msg.sender].push(activeRaffleId);
        }

        emit RaffleEntered(activeRaffleId, msg.sender, entries, msg.value);

        // Auto-close if max participants reached
        if (raffle.maxParticipants > 0 && raffle.participants.length >= raffle.maxParticipants) {
            _closeRaffle(activeRaffleId);
        }
    }

    /**
     * @dev Enter the active raffle with one entry
     */
    function enter() public payable {
        enterRaffle(1);
    }

    /**
     * @dev Close the active raffle
     * @param raffleId Raffle ID to close
     */
    function closeRaffle(uint256 raffleId) 
        public 
        onlyOwner 
        raffleExists(raffleId)
        raffleOpen(raffleId)
    {
        _closeRaffle(raffleId);
    }

    /**
     * @dev Internal function to close raffle
     * @param raffleId Raffle ID
     */
    function _closeRaffle(uint256 raffleId) private {
        Raffle storage raffle = raffles[raffleId];
        require(raffle.participants.length > 0, "No participants");

        raffle.status = RaffleStatus.Closed;
        raffle.closedAt = block.timestamp;

        if (activeRaffleId == raffleId) {
            activeRaffleId = 0;
        }

        emit RaffleClosed(raffleId, raffle.participants.length, raffle.prizePool);
    }

    /**
     * @dev Draw winner for a closed raffle
     * @param raffleId Raffle ID
     */
    function drawWinner(uint256 raffleId) 
        public 
        onlyOwner 
        raffleExists(raffleId)
        raffleClosed(raffleId)
    {
        Raffle storage raffle = raffles[raffleId];
        require(raffle.participants.length > 0, "No participants");

        // Generate pseudo-random winner index
        uint256 winnerIndex = _generateRandomNumber(raffleId) % raffle.participants.length;
        address winner = raffle.participants[winnerIndex];

        raffle.winner = winner;
        raffle.status = RaffleStatus.Drawn;
        raffle.drawnAt = block.timestamp;

        // Calculate prize and owner fee
        uint256 ownerFee = (raffle.prizePool * ownerFeePercent) / 10000;
        uint256 prize = raffle.prizePool - ownerFee;

        // Transfer prize to winner
        payable(winner).transfer(prize);

        // Transfer fee to owner
        if (ownerFee > 0) {
            payable(owner).transfer(ownerFee);
        }

        // Update winner stats
        ParticipantStats storage stats = participantStats[winner];
        stats.rafflesWon++;
        stats.totalWinnings += prize;

        emit WinnerDrawn(raffleId, winner, prize, block.timestamp);
        emit PrizeWithdrawn(raffleId, winner, prize);
    }

    /**
     * @dev Generate pseudo-random number
     * @param raffleId Raffle ID
     * @return Random number
     */
    function _generateRandomNumber(uint256 raffleId) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    raffleId,
                    raffles[raffleId].participants.length,
                    msg.sender
                )
            )
        );
    }

    /**
     * @dev Get raffle details
     * @param raffleId Raffle ID
     * @return Raffle details
     */
    function getRaffle(uint256 raffleId) 
        public 
        view 
        raffleExists(raffleId)
        returns (Raffle memory) 
    {
        return raffles[raffleId];
    }

    /**
     * @dev Get raffle participants
     * @param raffleId Raffle ID
     * @return Array of participant addresses
     */
    function getRaffleParticipants(uint256 raffleId) 
        public 
        view 
        raffleExists(raffleId)
        returns (address[] memory) 
    {
        return raffles[raffleId].participants;
    }

    /**
     * @dev Get participant entry count for a raffle
     * @param raffleId Raffle ID
     * @param participant Participant address
     * @return Number of entries
     */
    function getParticipantEntryCount(uint256 raffleId, address participant) 
        public 
        view 
        returns (uint256) 
    {
        return participantEntryCount[raffleId][participant];
    }

    /**
     * @dev Get all raffles
     * @return Array of all raffles
     */
    function getAllRaffles() public view returns (Raffle[] memory) {
        Raffle[] memory allRaffles = new Raffle[](allRaffleIds.length);
        
        for (uint256 i = 0; i < allRaffleIds.length; i++) {
            allRaffles[i] = raffles[allRaffleIds[i]];
        }
        
        return allRaffles;
    }

    /**
     * @dev Get raffles by status
     * @param status Raffle status
     * @return Array of raffles with the specified status
     */
    function getRafflesByStatus(RaffleStatus status) public view returns (Raffle[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allRaffleIds.length; i++) {
            if (raffles[allRaffleIds[i]].status == status) {
                count++;
            }
        }

        Raffle[] memory result = new Raffle[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allRaffleIds.length; i++) {
            Raffle memory raffle = raffles[allRaffleIds[i]];
            if (raffle.status == status) {
                result[index] = raffle;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get open raffles
     * @return Array of open raffles
     */
    function getOpenRaffles() public view returns (Raffle[] memory) {
        return getRafflesByStatus(RaffleStatus.Open);
    }

    /**
     * @dev Get closed raffles
     * @return Array of closed raffles
     */
    function getClosedRaffles() public view returns (Raffle[] memory) {
        return getRafflesByStatus(RaffleStatus.Closed);
    }

    /**
     * @dev Get drawn raffles
     * @return Array of drawn raffles
     */
    function getDrawnRaffles() public view returns (Raffle[] memory) {
        return getRafflesByStatus(RaffleStatus.Drawn);
    }

    /**
     * @dev Get active raffle
     * @return Active raffle details (or empty if none)
     */
    function getActiveRaffle() public view returns (Raffle memory) {
        if (activeRaffleId == 0) {
            return Raffle({
                id: 0,
                entryFee: 0,
                prizePool: 0,
                participants: new address[](0),
                winner: address(0),
                status: RaffleStatus.Open,
                createdAt: 0,
                closedAt: 0,
                drawnAt: 0,
                maxParticipants: 0
            });
        }
        return raffles[activeRaffleId];
    }

    /**
     * @dev Get user's raffles
     * @param user User address
     * @return Array of raffle IDs
     */
    function getUserRaffles(address user) public view returns (uint256[] memory) {
        return userRaffleIds[user];
    }

    /**
     * @dev Get user's raffle details
     * @param user User address
     * @return Array of raffles
     */
    function getUserRaffleDetails(address user) public view returns (Raffle[] memory) {
        uint256[] memory ids = userRaffleIds[user];
        Raffle[] memory result = new Raffle[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = raffles[ids[i]];
        }

        return result;
    }

    /**
     * @dev Get participant statistics
     * @param participant Participant address
     * @return ParticipantStats structure
     */
    function getParticipantStats(address participant) 
        public 
        view 
        returns (ParticipantStats memory) 
    {
        return participantStats[participant];
    }

    /**
     * @dev Get raffles won by user
     * @param user User address
     * @return Array of raffles won
     */
    function getRafflesWonByUser(address user) public view returns (Raffle[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allRaffleIds.length; i++) {
            if (raffles[allRaffleIds[i]].winner == user) {
                count++;
            }
        }

        Raffle[] memory result = new Raffle[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allRaffleIds.length; i++) {
            Raffle memory raffle = raffles[allRaffleIds[i]];
            if (raffle.winner == user) {
                result[index] = raffle;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total raffle count
     * @return Total number of raffles
     */
    function getTotalRaffleCount() public view returns (uint256) {
        return raffleCounter;
    }

    /**
     * @dev Get raffle count by status
     * @param status Raffle status
     * @return Count of raffles with the specified status
     */
    function getRaffleCountByStatus(RaffleStatus status) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allRaffleIds.length; i++) {
            if (raffles[allRaffleIds[i]].status == status) {
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
     * @dev Check if user is participating in raffle
     * @param raffleId Raffle ID
     * @param user User address
     * @return true if user is participating
     */
    function isParticipating(uint256 raffleId, address user) 
        public 
        view 
        raffleExists(raffleId)
        returns (bool) 
    {
        return participantEntryCount[raffleId][user] > 0;
    }

    /**
     * @dev Update owner fee percent
     * @param newFeePercent New fee percent in basis points
     */
    function setOwnerFeePercent(uint256 newFeePercent) public onlyOwner {
        require(newFeePercent <= 1000, "Fee cannot exceed 10%");
        ownerFeePercent = newFeePercent;
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
