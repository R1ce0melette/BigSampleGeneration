// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainRaffle
 * @dev A contract for an on-chain raffle where participants pay to enter and one random winner gets the pot.
 */
contract OnChainRaffle {
    address public owner;
    uint256 public ticketPrice;
    address payable[] public participants;
    bool public isRaffleOpen;

    event RaffleEntered(address indexed participant);
    event WinnerPicked(address indexed winner, uint256 prizeAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    /**
     * @dev Sets up the raffle with a ticket price.
     * @param _ticketPrice The cost to enter the raffle.
     */
    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        isRaffleOpen = true;
    }

    /**
     * @dev Allows a user to enter the raffle by paying the ticket price.
     */
    function enter() external payable {
        require(isRaffleOpen, "Raffle is not open.");
        require(msg.value == ticketPrice, "Incorrect ticket price.");
        
        participants.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev Generates a pseudo-random number to select a winner.
     * WARNING: This is not a secure source of randomness for production use.
     * @return A pseudo-random index for the participants array.
     */
    function _generateRandomIndex() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants.length))) % participants.length;
    }

    /**
     * @dev The owner picks a random winner and transfers the entire pot.
     * This also resets the raffle for a new round.
     */
    function pickWinner() external onlyOwner {
        require(participants.length > 0, "No participants in the raffle.");
        require(isRaffleOpen, "Raffle is not open.");

        isRaffleOpen = false;
        uint256 winnerIndex = _generateRandomIndex();
        address payable winner = participants[winnerIndex];
        uint256 prizeAmount = address(this).balance;

        (bool success, ) = winner.call{value: prizeAmount}("");
        require(success, "Transfer to winner failed.");

        emit WinnerPicked(winner, prizeAmount);

        // Reset the raffle
        participants = new address payable[](0);
        isRaffleOpen = true;
    }

    /**
     * @dev Allows the owner to close the raffle and refund all participants.
     */
    function cancelRaffle() external onlyOwner {
        require(isRaffleOpen, "Raffle is not open.");
        isRaffleOpen = false;

        for (uint i = 0; i < participants.length; i++) {
            (bool success, ) = participants[i].call{value: ticketPrice}("");
            require(success, "Refund failed.");
        }
        
        // Reset participants array
        participants = new address payable[](0);
    }

    /**
     * @dev Returns the list of participants.
     * @return An array of participant addresses.
     */
    function getParticipants() external view returns (address payable[] memory) {
        return participants;
    }
}
