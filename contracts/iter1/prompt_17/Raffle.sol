// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    address[] public participants;
    uint256 public ticketPrice;
    bool public isOpen;

    event Entered(address indexed participant);
    event WinnerSelected(address indexed winner, uint256 amount);
    event RaffleOpened(uint256 ticketPrice);
    event RaffleClosed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        isOpen = false;
    }

    function openRaffle() external onlyOwner {
        require(!isOpen, "Raffle already open");
        delete participants;
        isOpen = true;
        emit RaffleOpened(ticketPrice);
    }

    function enter() external payable {
        require(isOpen, "Raffle not open");
        require(msg.value == ticketPrice, "Incorrect ticket price");
        participants.push(msg.sender);
        emit Entered(msg.sender);
    }

    function closeRaffleAndPickWinner() external onlyOwner {
        require(isOpen, "Raffle not open");
        require(participants.length > 0, "No participants");
        isOpen = false;
    uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants.length))) % participants.length;
        address winner = participants[winnerIndex];
        uint256 prize = address(this).balance;
        payable(winner).transfer(prize);
        emit WinnerSelected(winner, prize);
        emit RaffleClosed();
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
}
