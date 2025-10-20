// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenFaucet {
    IERC20 public token;
    uint256 public constant FAUCET_AMOUNT = 100 * 10**18;
    uint256 public constant WAIT_TIME = 1 days;
    mapping(address => uint256) public lastClaim;

    event Claimed(address indexed user, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Invalid token");
        token = IERC20(_token);
    }

    function claim() external {
        require(block.timestamp - lastClaim[msg.sender] >= WAIT_TIME, "Wait 24h between claims");
        lastClaim[msg.sender] = block.timestamp;
        require(token.transfer(msg.sender, FAUCET_AMOUNT), "Transfer failed");
        emit Claimed(msg.sender, FAUCET_AMOUNT);
    }
}
