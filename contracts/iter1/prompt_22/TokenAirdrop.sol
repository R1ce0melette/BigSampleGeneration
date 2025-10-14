// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenAirdrop {
    address public owner;
    IERC20 public token;
    mapping(address => bool) public claimed;

    event Airdropped(address indexed user, uint256 amount);

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
        for (uint i = 0; i < recipients.length; i++) {
            require(!claimed[recipients[i]], "Already claimed");
            claimed[recipients[i]] = true;
            require(token.transfer(recipients[i], amount), "Transfer failed");
            emit Airdropped(recipients[i], amount);
        }
    }
}
