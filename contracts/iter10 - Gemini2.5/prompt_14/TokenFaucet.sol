// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenFaucet {
    address public owner;
    IERC20 public token;
    uint256 public claimAmount;
    mapping(address => uint256) public lastClaimed;

    event TokensClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor(address _tokenAddress, uint256 _claimAmount) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        claimAmount = _claimAmount;
    }

    function claim() public {
        require(lastClaimed[msg.sender] + 24 hours <= block.timestamp, "You can only claim once every 24 hours.");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet is empty.");

        lastClaimed[msg.sender] = block.timestamp;
        require(token.transfer(msg.sender, claimAmount), "Token transfer failed.");

        emit TokensClaimed(msg.sender, claimAmount);
    }

    function setClaimAmount(uint256 _newAmount) public onlyOwner {
        claimAmount = _newAmount;
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance in faucet.");
        require(token.transfer(owner, _amount), "Token transfer failed.");
    }
}
