// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address[] public participants;
    uint256 public ticketPrice;
    address public owner;
    bool public ended;
    address public winner;

    event Entered(address indexed participant);
    event WinnerSelected(address indexed winner);

    constructor(uint256 _ticketPrice) {
        ticketPrice = _ticketPrice;
        owner = msg.sender;
    }

    function enter() external payable {
        require(!ended, "Raffle ended");
        require(msg.value == ticketPrice, "Incorrect ticket price");
        participants.push(msg.sender);
        emit Entered(msg.sender);
    }

    function pickWinner() external {
        require(msg.sender == owner, "Not owner");
        require(!ended, "Raffle ended");
        require(participants.length > 0, "No participants");
    uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants)));
        uint256 winnerIndex = rand % participants.length;
        winner = participants[winnerIndex];
        ended = true;
        payable(winner).transfer(address(this).balance);
        emit WinnerSelected(winner);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
}
