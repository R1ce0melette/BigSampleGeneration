// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20
 * @dev Interface for the ERC20 standard.
 */
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title TokenAirdrop
 * @dev A contract to airdrop a specified amount of ERC20 tokens to a list of addresses.
 */
contract TokenAirdrop {
    address public owner;
    IERC20 public token;

    event Airdropped(address indexed recipient, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    /**
     * @dev Sets the token contract address.
     * @param _tokenAddress The address of the ERC20 token to be airdropped.
     */
    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Airdrops a specific amount of tokens to a list of recipients.
     * The contract must have sufficient token balance to perform the airdrop.
     * @param _recipients An array of addresses to receive the tokens.
     * @param _amount The amount of tokens to send to each recipient.
     */
    function airdrop(address[] memory _recipients, uint256 _amount) external onlyOwner {
        require(_recipients.length > 0, "Recipient list cannot be empty.");
        require(_amount > 0, "Amount must be greater than zero.");

        uint256 totalAmount = _recipients.length * _amount;
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance for airdrop.");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Cannot airdrop to the zero address.");
            bool success = token.transfer(_recipients[i], _amount);
            // If a transfer fails, it will revert the whole transaction.
            // This ensures atomicity.
            require(success, "Token transfer failed.");
            emit Airdropped(_recipients[i], _amount);
        }
    }

    /**
     * @dev Airdrops varying amounts of tokens to a list of recipients.
     * @param _recipients An array of addresses to receive the tokens.
     * @param _amounts An array of token amounts corresponding to each recipient.
     */
    function bulkAirdrop(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length > 0, "Recipient list cannot be empty.");
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must have the same length.");

        uint256 totalAmount = 0;
        for(uint i = 0; i < _amounts.length; i++){
            totalAmount += _amounts[i];
        }
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance for airdrop.");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Cannot airdrop to the zero address.");
            require(_amounts[i] > 0, "Amount must be greater than zero.");
            bool success = token.transfer(_recipients[i], _amounts[i]);
            require(success, "Token transfer failed.");
            emit Airdropped(_recipients[i], _amounts[i]);
        }
    }

    /**
     * @dev Allows the owner to withdraw any remaining tokens from the contract.
     */
    function withdrawRemainingTokens() external onlyOwner {
        uint256 remainingBalance = token.balanceOf(address(this));
        require(remainingBalance > 0, "No tokens to withdraw.");
        
        bool success = token.transfer(owner, remainingBalance);
        require(success, "Withdrawal failed.");
        emit TokensWithdrawn(owner, remainingBalance);
    }
}
