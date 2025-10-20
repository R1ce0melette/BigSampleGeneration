// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    address public owner;
    IERC20 public token;

    event Airdropped(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    function airdrop(address[] memory _recipients, uint256[] memory _amounts) public onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must have the same length.");

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Recipient cannot be the zero address.");
            require(_amounts[i] > 0, "Amount must be greater than zero.");
            
            require(token.transfer(_recipients[i], _amounts[i]), "Token transfer failed.");
            emit Airdropped(_recipients[i], _amounts[i]);
        }
    }
}
