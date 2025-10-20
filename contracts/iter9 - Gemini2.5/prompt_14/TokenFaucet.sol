// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenFaucet {
    address public owner;
    address public tokenAddress;
    uint256 public claimAmount;
    uint256 public claimInterval;
    mapping(address => uint256) public lastClaimed;

    event TokensClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(address _tokenAddress, uint256 _claimAmount, uint256 _claimInterval) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        claimAmount = _claimAmount;
        claimInterval = _claimInterval;
    }

    function claimTokens() public {
        require(tokenAddress != address(0), "Token address not set.");
        require(lastClaimed[msg.sender] + claimInterval <= block.timestamp, "You can only claim tokens once per interval.");
        
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet is empty.");

        lastClaimed[msg.sender] = block.timestamp;
        token.transfer(msg.sender, claimAmount);
        
        emit TokensClaimed(msg.sender, claimAmount);
    }

    function setToken(address _newTokenAddress) public onlyOwner {
        tokenAddress = _newTokenAddress;
    }

    function setClaimAmount(uint256 _newClaimAmount) public onlyOwner {
        claimAmount = _newClaimAmount;
    }

    function setClaimInterval(uint256 _newClaimInterval) public onlyOwner {
        claimInterval = _newClaimInterval;
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance in faucet.");
        token.transfer(owner, _amount);
    }
}
