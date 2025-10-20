// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenFaucet {
    address public owner;
    IERC20 public token;
    uint256 public claimAmount;
    uint256 public constant COOLDOWN = 24 hours;

    mapping(address => uint256) public lastClaimTime;

    event TokensClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(address _tokenAddress, uint256 _claimAmount) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        claimAmount = _claimAmount;
    }

    function claimTokens() public {
        require(lastClaimTime[msg.sender] + COOLDOWN <= block.timestamp, "You can only claim once every 24 hours.");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet does not have enough tokens.");

        lastClaimTime[msg.sender] = block.timestamp;
        bool success = token.transfer(msg.sender, claimAmount);
        require(success, "Token transfer failed.");

        emit TokensClaimed(msg.sender, claimAmount);
    }

    function setClaimAmount(uint256 _newAmount) public onlyOwner {
        claimAmount = _newAmount;
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)), "Insufficient balance in faucet.");
        bool success = token.transfer(owner, _amount);
        require(success, "Token transfer failed.");
    }
}
