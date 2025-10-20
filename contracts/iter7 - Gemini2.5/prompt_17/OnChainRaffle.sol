// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainRaffle
 * @dev A contract for an on-chain raffle where participants buy tickets to win the prize pool.
 */
contract OnChainRaffle {
    address public owner;
    uint256 public ticketPrice;
    address[] public participants;
    bool public isRaffleOpen;
    address public winner;

    /**
     * @dev Emitted when the raffle is started.
     * @param ticketPrice The price of one raffle ticket.
     */
    event RaffleStarted(uint256 ticketPrice);

    /**
     * @dev Emitted when a participant enters the raffle.
     * @param participant The address of the participant.
     */
    event ParticipantEntered(address indexed participant);

    /**
     * @dev Emitted when a winner is chosen.
     * @param winner The address of the winner.
     * @param prizeAmount The total prize amount won.
     */
    event WinnerChosen(address indexed winner, uint256 prizeAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "OnChainRaffle: Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Starts a new raffle.
     * @param _ticketPrice The price for each ticket in wei.
     */
    function startRaffle(uint256 _ticketPrice) public onlyOwner {
        require(!isRaffleOpen, "OnChainRaffle: A raffle is already open.");
        require(_ticketPrice > 0, "OnChainRaffle: Ticket price must be greater than zero.");

        ticketPrice = _ticketPrice;
        isRaffleOpen = true;
        delete participants; // Clear participants from the previous raffle
        winner = address(0); // Reset winner

        emit RaffleStarted(_ticketPrice);
    }

    /**
     * @dev Allows a user to enter the raffle by purchasing a ticket.
     */
    function enter() public payable {
        require(isRaffleOpen, "OnChainRaffle: The raffle is not open.");
        require(msg.value == ticketPrice, "OnChainRaffle: Incorrect ticket price.");

        participants.push(msg.sender);
        emit ParticipantEntered(msg.sender);
    }

    /**
     * @dev Chooses a random winner from the participants and sends them the prize pool.
     * This is a pseudo-random method and is not secure for high-value raffles.
     */
    function pickWinner() public onlyOwner {
        require(isRaffleOpen, "OnChainRaffle: The raffle is not open.");
        require(participants.length > 0, "OnChainRaffle: No participants in the raffle.");

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants.length))) % participants.length;
        winner = participants[randomIndex];
        isRaffleOpen = false;

        uint256 prizeAmount = address(this).balance;
        (bool success, ) = payable(winner).call{value: prizeAmount}("");
        require(success, "OnChainRaffle: Failed to send prize to the winner.");

        emit WinnerChosen(winner, prizeAmount);
    }

    /**
     * @dev Returns the list of all participants in the current raffle.
     * @return An array of participant addresses.
     */
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }
}
