// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    address[] public participants;
    uint256 public ticketPrice;
    bool public raffleOpen;
    address public winner;

    event Entered(address indexed participant);
    event WinnerSelected(address indexed winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        raffleOpen = true;
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
    uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants)));
    uint256 winnerIndex = rand % participants.length;
    winner = participants[winnerIndex];
    raffleOpen = false;
    payable(winner).transfer(address(this).balance);
    emit WinnerSelected(winner, address(this).balance);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
}
