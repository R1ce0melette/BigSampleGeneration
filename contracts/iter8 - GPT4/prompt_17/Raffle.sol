// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address[] public participants;
    uint256 public ticketPrice;
    address public owner;
    bool public ended;
    address public winner;

    event Entered(address indexed participant);
    event WinnerSelected(address indexed winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _ticketPrice) {
        require(_ticketPrice > 0, "Ticket price must be positive");
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }

    function enter() external payable {
        require(!ended, "Raffle ended");
        require(msg.value == ticketPrice, "Incorrect ETH");
        participants.push(msg.sender);
        emit Entered(msg.sender);
    }

    function pickWinner() external onlyOwner {
        require(!ended, "Raffle ended");
        require(participants.length > 0, "No participants");
    uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants)));
        uint256 winnerIndex = rand % participants.length;
        winner = participants[winnerIndex];
        ended = true;
        uint256 prize = address(this).balance;
        (bool sent, ) = winner.call{value: prize}("");
        require(sent, "Transfer failed");
        emit WinnerSelected(winner, prize);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
}
