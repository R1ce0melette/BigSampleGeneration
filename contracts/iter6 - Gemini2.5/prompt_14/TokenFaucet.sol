// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenFaucet {
    IERC20 public token;
    uint256 public dripAmount;
    uint256 public cooldown = 24 hours;
    mapping(address => uint256) public lastClaimed;

    event TokensClaimed(address indexed user, uint256 amount);

    constructor(address _tokenAddress, uint256 _dripAmount) {
        token = IERC20(_tokenAddress);
        dripAmount = _dripAmount;
    }

    function claimTokens() public {
        require(block.timestamp >= lastClaimed[msg.sender] + cooldown, "You can only claim once every 24 hours.");
        require(token.balanceOf(address(this)) >= dripAmount, "Faucet is empty.");

        lastClaimed[msg.sender] = block.timestamp;
        token.transfer(msg.sender, dripAmount);

        emit TokensClaimed(msg.sender, dripAmount);
    }
}
