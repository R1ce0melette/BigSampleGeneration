// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint256 public entryFee;
    address[] public participants;
    bool public raffleOpen;

    event Entered(address indexed participant);
    event WinnerPicked(address indexed winner, uint256 prizeAmount);

    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
        raffleOpen = true;
    }

    function enter() public payable {
        require(raffleOpen, "Raffle is closed.");
        require(msg.value == entryFee, "Incorrect entry fee.");
        participants.push(msg.sender);
        emit Entered(msg.sender);
    }

    function pickWinner() public {
        require(msg.sender == owner, "Only the owner can pick the winner.");
        require(raffleOpen, "Raffle is already closed.");
        require(participants.length > 0, "No participants in the raffle.");

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % participants.length;
        address winner = participants[randomIndex];
        
        raffleOpen = false;
        uint256 prizeAmount = address(this).balance;
        
        payable(winner).transfer(prizeAmount);

        emit WinnerPicked(winner, prizeAmount);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
    }
}
