// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20
 * @dev Minimal interface for an ERC20 token.
 */
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title TokenAirdrop
 * @dev A contract to airdrop a fixed amount of tokens to a list of addresses.
 */
contract TokenAirdrop {
    address public owner;
    IERC20 public immutable token;

    event Airdropped(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Airdrops a specified amount of tokens to a list of recipients.
     * @param _recipients An array of addresses to receive the tokens.
     * @param _amount The amount of tokens to send to each recipient.
     */
    function airdrop(address[] memory _recipients, uint256 _amount) public onlyOwner {
        require(_recipients.length > 0, "Recipient list cannot be empty.");
        require(_amount > 0, "Airdrop amount must be positive.");
        
        uint256 totalAmount = _recipients.length * _amount;
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance for airdrop.");

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Cannot airdrop to the zero address.");
            token.transfer(_recipients[i], _amount);
            emit Airdropped(_recipients[i], _amount);
        }
    }

    /**
     * @dev Allows the owner to withdraw any remaining tokens from the contract.
     */
    function withdrawRemainingTokens() public onlyOwner {
        uint256 remainingBalance = token.balanceOf(address(this));
        if (remainingBalance > 0) {
            token.transfer(owner, remainingBalance);
        }
    }
}
