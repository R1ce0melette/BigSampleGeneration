// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenFaucet {
    address public owner;
    IERC20 public token;
    uint256 public dripAmount;
    uint256 public cooldown = 24 hours;
    mapping(address => uint256) public lastClaimed;

    event TokensClaimed(address indexed user, uint256 amount);
    event FundsDeposited(address indexed from, uint256 amount);

    constructor(address _tokenAddress, uint256 _dripAmount) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        dripAmount = _dripAmount;
    }

    function deposit(uint256 _amount) public {
        require(msg.sender == owner, "Only owner can deposit funds.");
        // This function assumes the owner has approved the faucet contract to spend their tokens
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
        emit FundsDeposited(msg.sender, _amount);
    }

    function claim() public {
        require(lastClaimed[msg.sender] + cooldown <= block.timestamp, "You must wait 24 hours between claims.");
        require(token.balanceOf(address(this)) >= dripAmount, "Faucet is empty.");

        lastClaimed[msg.sender] = block.timestamp;
        require(token.transfer(msg.sender, dripAmount), "Token transfer failed.");

        emit TokensClaimed(msg.sender, dripAmount);
    }

    function getFaucetBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getLastClaimTime(address _user) public view returns (uint256) {
        return lastClaimed[_user];
    }
}
