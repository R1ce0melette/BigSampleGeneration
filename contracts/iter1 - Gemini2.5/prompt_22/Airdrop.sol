// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Airdrop {
    address public owner;
    IERC20 public token;

    event Airdropped(address indexed recipient, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    function airdrop(address[] calldata _recipients, uint256[] calldata _amounts) public onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must have the same length.");
        
        uint256 totalAmount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        
        require(token.balanceOf(address(this)) >= totalAmount, "Contract does not have enough tokens for this airdrop.");

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Cannot send to the zero address.");
            bool success = token.transfer(_recipients[i], _amounts[i]);
            if(success) {
                emit Airdropped(_recipients[i], _amounts[i]);
            }
        }
    }

    // In case some tokens are left over or need to be recovered
    function withdrawRemainingTokens() public onlyOwner {
        uint256 remainingBalance = token.balanceOf(address(this));
        require(remainingBalance > 0, "No tokens to withdraw.");
        
        bool success = token.transfer(owner, remainingBalance);
        require(success, "Token transfer failed.");
        emit TokensWithdrawn(owner, remainingBalance);
    }
}
