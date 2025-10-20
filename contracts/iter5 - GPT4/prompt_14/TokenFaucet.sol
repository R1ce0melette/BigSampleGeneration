// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenFaucet {
    IERC20 public token;
    uint256 public claimAmount;
    mapping(address => uint256) public lastClaimed;

    event Claimed(address indexed user, uint256 amount, uint256 timestamp);

    constructor(address _token, uint256 _claimAmount) {
        token = IERC20(_token);
        claimAmount = _claimAmount;
    }

    function claim() external {
        require(block.timestamp - lastClaimed[msg.sender] >= 1 days, "Wait 24h between claims");
        lastClaimed[msg.sender] = block.timestamp;
        require(token.transfer(msg.sender, claimAmount), "Transfer failed");
        emit Claimed(msg.sender, claimAmount, block.timestamp);
    }
}
