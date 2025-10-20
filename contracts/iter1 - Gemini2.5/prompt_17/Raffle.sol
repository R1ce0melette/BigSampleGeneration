// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint256 public entryFee;
    address payable[] public participants;
    bool public isOpen;

    event RaffleEnter(address indexed participant);
    event WinnerPicked(address indexed winner, uint256 prizeAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
        isOpen = true;
    }

    function enter() public payable {
        require(isOpen, "Raffle is not open.");
        require(msg.value == entryFee, "Incorrect entry fee.");
        participants.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function pickWinner() public onlyOwner {
        require(isOpen, "Raffle has already ended.");
        require(participants.length > 0, "No participants in the raffle.");

        uint256 winnerIndex = _generateRandomNumber() % participants.length;
        address payable winner = participants[winnerIndex];
        
        uint256 prizeAmount = address(this).balance;
        
        isOpen = false;

        winner.transfer(prizeAmount);
        emit WinnerPicked(winner, prizeAmount);
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function startNewRaffle() public onlyOwner {
        require(!isOpen, "Current raffle is still open.");
        delete participants;
        isOpen = true;
    }

    function _generateRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants)));
    }
}
