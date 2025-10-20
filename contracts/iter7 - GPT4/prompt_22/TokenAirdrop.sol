// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenAirdrop {
    address public owner;
    IERC20 public token;
    mapping(address => uint256) public airdropAmounts;
    mapping(address => bool) public claimed;

    event AirdropSet(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        owner = msg.sender;
        token = IERC20(_token);
    }

    function setAirdrop(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
        require(users.length == amounts.length, "Length mismatch");
        for (uint256 i = 0; i < users.length; i++) {
            airdropAmounts[users[i]] = amounts[i];
            emit AirdropSet(users[i], amounts[i]);
        }
    }

    function claim() external {
        require(!claimed[msg.sender], "Already claimed");
        uint256 amount = airdropAmounts[msg.sender];
        require(amount > 0, "No airdrop");
        claimed[msg.sender] = true;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Claimed(msg.sender, amount);
    }
}
