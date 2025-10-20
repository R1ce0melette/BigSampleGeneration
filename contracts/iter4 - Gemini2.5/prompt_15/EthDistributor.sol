// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthDistributor {
    address public owner;

    event Distributed(address indexed recipient, uint256 amount);
    event FundsDeposited(address indexed from, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function deposit() public payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function distribute(address payable[] memory _recipients) public onlyOwner {
        uint256 totalRecipients = _recipients.length;
        require(totalRecipients > 0, "Recipient list cannot be empty.");
        
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "No funds to distribute.");

        uint256 amountPerRecipient = totalBalance / totalRecipients;
        require(amountPerRecipient > 0, "Distribution amount per recipient is zero.");

        for (uint i = 0; i < totalRecipients; i++) {
            _recipients[i].transfer(amountPerRecipient);
            emit Distributed(_recipients[i], amountPerRecipient);
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
