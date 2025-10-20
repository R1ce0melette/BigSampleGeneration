// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address[] public participants;
    uint256 public ticketPrice;
    address public owner;
    bool public raffleOpen;
    address public winner;

    event Entered(address indexed participant);
    event WinnerSelected(address indexed winner, uint256 amount);
    event RaffleStarted(uint256 ticketPrice);
    event RaffleEnded();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _ticketPrice) {
        require(_ticketPrice > 0, "Ticket price must be positive");
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        raffleOpen = true;
        emit RaffleStarted(_ticketPrice);
    }

    function enter() external payable {
        require(raffleOpen, "Raffle closed");
        require(msg.value == ticketPrice, "Incorrect ticket price");
        participants.push(msg.sender);
        emit Entered(msg.sender);
    }

    function pickWinner() external onlyOwner {
    require(raffleOpen, "Raffle closed");
    require(participants.length > 0, "No participants");
    uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants)));
    uint256 winnerIndex = random % participants.length;
    winner = participants[winnerIndex];
    uint256 prize = address(this).balance;
    raffleOpen = false;
    payable(winner).transfer(prize);
    emit WinnerSelected(winner, prize);
    emit RaffleEnded();
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
}
