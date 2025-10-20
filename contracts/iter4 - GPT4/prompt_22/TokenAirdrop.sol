// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenAirdrop {
    address public owner;
    IERC20 public token;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    function airdrop(address[] calldata recipients, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be positive");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amount), "Transfer failed");
        }
    }
}
