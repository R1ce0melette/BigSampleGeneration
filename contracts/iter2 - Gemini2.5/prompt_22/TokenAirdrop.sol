// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenAirdrop is Ownable {
    IERC20 public token;

    event Airdropped(address indexed recipient, uint256 amount);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Token address cannot be zero.");
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Distributes a specified amount of tokens to a list of recipient addresses.
     *      The contract must have enough tokens approved for transfer by the owner.
     * @param _recipients An array of addresses to receive the tokens.
     * @param _amount The amount of tokens to send to each recipient.
     */
    function airdrop(address[] memory _recipients, uint256 _amount) public onlyOwner {
        require(_recipients.length > 0, "Recipient list cannot be empty.");
        require(_amount > 0, "Amount must be greater than zero.");

        uint256 totalAmount = _recipients.length * _amount;
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance in the contract.");

        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            if (recipient != address(0)) {
                bool success = token.transfer(recipient, _amount);
                if (success) {
                    emit Airdropped(recipient, _amount);
                }
            }
        }
    }

    /**
     * @dev Allows the owner to withdraw any remaining tokens from the contract.
     *      This is useful if there are leftover tokens after an airdrop.
     */
    function withdrawRemainingTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            bool success = token.transfer(owner(), balance);
            require(success, "Token transfer failed.");
        }
    }
}
