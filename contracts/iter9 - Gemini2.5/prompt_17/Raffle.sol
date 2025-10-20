// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;
    uint256 public entryFee;
    address[] public participants;
    bool public raffleOpen;

    event Entered(address indexed participant);
    event WinnerPicked(address indexed winner, uint256 prize);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

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

    function pickWinner() public onlyOwner {
        require(raffleOpen, "Raffle is already closed.");
        require(participants.length > 0, "No participants in the raffle.");

        uint256 winnerIndex = _random() % participants.length;
        address winner = participants[winnerIndex];
        uint256 prize = address(this).balance;

        raffleOpen = false;
        payable(winner).transfer(prize);

        emit WinnerPicked(winner, prize);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    function getPot() public view returns (uint256) {
        return address(this).balance;
    }

    function _random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants)));
    }
}
