// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainRaffle
 * @dev A contract for an on-chain raffle where participants pay to enter,
 * and a random winner is chosen to receive the entire prize pot.
 */
contract OnChainRaffle {
    address public owner;
    uint256 public entryFee;
    address[] public participants;
    bool public isRaffleOpen;

    /**
     * @dev Emitted when a new raffle is started.
     * @param entryFee The fee required to enter the raffle.
     */
    event RaffleStarted(uint256 entryFee);

    /**
     * @dev Emitted when a participant enters the raffle.
     * @param participant The address of the participant.
     */
    event ParticipantEntered(address indexed participant);

    /**
     * @dev Emitted when a winner is chosen and the prize is awarded.
     * @param winner The address of the winner.
     * @param prizeAmount The total prize amount won.
     */
    event WinnerChosen(address indexed winner, uint256 prizeAmount);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the contract owner upon deployment.
     */
    constructor() {
        owner = msg.sender;
        isRaffleOpen = false;
    }

    /**
     * @dev Starts a new raffle with a specified entry fee.
     * Only the owner can start a raffle, and only when one is not already open.
     * @param _entryFee The fee to enter the raffle, in wei.
     */
    function startRaffle(uint256 _entryFee) public onlyOwner {
        require(!isRaffleOpen, "A raffle is already open.");
        require(_entryFee > 0, "Entry fee must be greater than zero.");
        
        entryFee = _entryFee;
        isRaffleOpen = true;
        delete participants; // Clear participants from the previous raffle

        emit RaffleStarted(_entryFee);
    }

    /**
     * @dev Allows a user to enter the raffle by paying the entry fee.
     */
    function enter() public payable {
        require(isRaffleOpen, "The raffle is not currently open.");
        require(msg.value == entryFee, "Incorrect entry fee paid.");
        
        participants.push(msg.sender);
        emit ParticipantEntered(msg.sender);
    }

    /**
     * @dev Chooses a random winner from the participants and sends them the prize pot.
     * Only the owner can trigger the winner selection.
     * This uses a pseudo-random method and is not suitable for high-stakes raffles.
     */
    function pickWinner() public onlyOwner {
        require(isRaffleOpen, "The raffle is not open.");
        require(participants.length > 0, "No participants in the raffle.");

        isRaffleOpen = false;
        
        uint256 randomIndex = _pseudoRandom() % participants.length;
        address payable winner = payable(participants[randomIndex]);
        
        uint256 prizeAmount = address(this).balance;
        
        (bool success, ) = winner.call{value: prizeAmount}("");
        require(success, "Failed to send prize to the winner.");

        emit WinnerChosen(winner, prizeAmount);
    }

    /**
     * @dev Generates a pseudo-random number based on block attributes.
     * WARNING: This is not truly random and can be manipulated by miners.
     * It is suitable for low-stakes applications only.
     * @return A pseudo-random number.
     */
    function _pseudoRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            participants.length
        )));
    }

    /**
     * @dev Returns the list of all participants in the current raffle.
     */
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    /**
     * @dev Returns the current prize pot amount.
     */
    function getPrizePot() public view returns (uint256) {
        return address(this).balance;
    }
}
