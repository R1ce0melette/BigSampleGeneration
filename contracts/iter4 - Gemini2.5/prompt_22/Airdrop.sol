// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Airdrop {
    address public owner;
    IERC20 public token;

    event Airdropped(address indexed recipient, uint256 amount);
    event FundsDeposited(address indexed from, uint256 amount);

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function deposit(uint256 _amount) public onlyOwner {
        // Assumes owner has approved the contract to spend their tokens
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
        emit FundsDeposited(msg.sender, _amount);
    }

    function performAirdrop(address[] memory _recipients, uint256[] memory _amounts) public onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must have the same length.");
        
        uint256 totalAmount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance in contract for airdrop.");

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Cannot airdrop to the zero address.");
            require(token.transfer(_recipients[i], _amounts[i]), "Token transfer to recipient failed.");
            emit Airdropped(_recipients[i], _amounts[i]);
        }
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
