// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenAirdrop {
    address public owner;
    IERC20 public token;
    mapping(address => uint256) public allocations;
    mapping(address => bool) public claimed;

    event AirdropClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    function setAllocations(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            allocations[recipients[i]] = amounts[i];
        }
    }

    function claim() external {
        require(!claimed[msg.sender], "Already claimed");
        uint256 amount = allocations[msg.sender];
        require(amount > 0, "No allocation");
        claimed[msg.sender] = true;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit AirdropClaimed(msg.sender, amount);
    }
}
