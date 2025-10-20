// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Airdrop {
    address public owner;
    address public tokenAddress;

    event Airdropped(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function airdrop(address[] memory _recipients, uint256[] memory _amounts) public onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must have the same length.");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 totalAmount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance for the airdrop.");

        for (uint i = 0; i < _recipients.length; i++) {
            token.transfer(_recipients[i], _amounts[i]);
            emit Airdropped(_recipients[i], _amounts[i]);
        }
    }

    function setTokenAddress(address _newTokenAddress) public onlyOwner {
        tokenAddress = _newTokenAddress;
    }

    function withdrawRemainingTokens() public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 remainingBalance = token.balanceOf(address(this));
        if (remainingBalance > 0) {
            token.transfer(owner, remainingBalance);
        }
    }
}
