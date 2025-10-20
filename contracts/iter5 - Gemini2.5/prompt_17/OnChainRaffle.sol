// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainRaffle
 * @dev A contract for a raffle where participants enter to win a prize pot.
 */
contract OnChainRaffle {
    address public owner;
    uint256 public entryFee;
    address[] public participants;
    bool public isRaffleOpen;

    /**
     * @dev Event emitted when a participant enters the raffle.
     * @param participant The address of the participant.
     */
    event RaffleEntered(address indexed participant);

    /**
     * @dev Event emitted when the winner is picked.
     * @param winner The address of the winner.
     * @param prizeAmount The total prize amount won.
     */
    event WinnerPicked(address indexed winner, uint256 prizeAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets up the raffle with an entry fee.
     * @param _entryFee The cost to enter the raffle, in wei.
     */
    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
        isRaffleOpen = true;
    }

    /**
     * @dev Allows a user to enter the raffle by paying the entry fee.
     */
    function enter() public payable {
        require(isRaffleOpen, "Raffle is not currently open.");
        require(msg.value == entryFee, "Entry fee is not correct.");
        
        participants.push(msg.sender);
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev Picks a random winner from the participants and sends them the prize.
     * - Only the owner can trigger this.
     * - There must be at least one participant.
     */
    function pickWinner() public onlyOwner {
        require(participants.length > 0, "No participants in the raffle.");
        
        uint256 prizeAmount = address(this).balance;
        uint256 winnerIndex = _pseudoRandom() % participants.length;
        address payable winner = payable(participants[winnerIndex]);
        
        isRaffleOpen = false; // Close the raffle after picking a winner
        
        emit WinnerPicked(winner, prizeAmount);
        
        // Transfer the prize to the winner
        (bool sent, ) = winner.call{value: prizeAmount}("");
        require(sent, "Failed to send prize to the winner.");
        
        // Reset for the next raffle
        participants = new address[](0);
    }

    /**
     * @dev A simple pseudo-random number generator.
     * **Note:** This is not secure for high-value applications.
     * @return A pseudo-random number.
     */
    function _pseudoRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            participants.length
        )));
    }

    /**
     * @dev Starts a new raffle.
     * - Only the owner can start a new raffle.
     */
    function startNewRaffle() public onlyOwner {
        require(!isRaffleOpen, "A raffle is already open.");
        isRaffleOpen = true;
    }

    /**
     * @dev Returns the list of participants.
     * @return An array of participant addresses.
     */
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }
}
