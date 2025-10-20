// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Raffle is Ownable {
    uint256 public entryFee;
    address[] public participants;
    bool public raffleOpen;
    address public previousWinner;

    event RaffleOpened(uint256 entryFee);
    event Entered(address indexed participant);
    event WinnerPicked(address indexed winner, uint256 prizeAmount);

    constructor(uint256 _entryFee) Ownable(msg.sender) {
        entryFee = _entryFee;
        raffleOpen = true;
        emit RaffleOpened(_entryFee);
    }

    function enter() public payable {
        require(raffleOpen, "Raffle is not open.");
        require(msg.value == entryFee, "Incorrect entry fee.");
        participants.push(msg.sender);
        emit Entered(msg.sender);
    }

    function pickWinner() public onlyOwner {
        require(raffleOpen, "Raffle is not open.");
        require(participants.length > 0, "No participants in the raffle.");

        uint256 prizeAmount = address(this).balance;
        uint256 randomIndex = _generateRandomNumber() % participants.length;
        address winner = participants[randomIndex];

        previousWinner = winner;
        raffleOpen = false;

        // Reset for next raffle
        participants = new address[](0);

        emit WinnerPicked(winner, prizeAmount);
        payable(winner).transfer(prizeAmount);
    }

    function startNewRaffle(uint256 _newEntryFee) public onlyOwner {
        require(!raffleOpen, "Current raffle must be concluded before starting a new one.");
        entryFee = _newEntryFee;
        raffleOpen = true;
        emit RaffleOpened(_newEntryFee);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    function _generateRandomNumber() private view returns (uint256) {
        // In a real-world scenario, this is not a secure way to generate randomness.
        // For production, use a Chainlink VRF or a similar oracle service.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, participants)));
    }
}
