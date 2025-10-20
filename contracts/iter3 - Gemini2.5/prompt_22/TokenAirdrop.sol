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
 * @dev A contract to perform a token airdrop to a list of addresses.
 * The owner can initiate the airdrop, sending a specified amount of tokens
 * to each recipient.
 */
contract TokenAirdrop {
    address public owner;
    IERC20 public immutable token;

    /**
     * @dev Emitted when tokens are airdropped to a recipient.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens sent.
     */
    event Airdropped(address indexed recipient, uint256 amount);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets up the contract with the address of the ERC20 token.
     * @param _tokenAddress The address of the token to be airdropped.
     */
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token address cannot be the zero address.");
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Performs the airdrop to a list of recipients.
     * Each recipient receives the same specified amount of tokens.
     * @param _recipients An array of addresses to receive the airdrop.
     * @param _amount The amount of tokens to send to each recipient.
     */
    function airdrop(address[] memory _recipients, uint256 _amount) public onlyOwner {
        require(_recipients.length > 0, "Recipient list cannot be empty.");
        require(_amount > 0, "Airdrop amount must be greater than zero.");

        uint256 totalAmount = _recipients.length * _amount;
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance in the contract for the airdrop.");

        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            // Ensure recipient is not the zero address
            if (recipient != address(0)) {
                bool success = token.transfer(recipient, _amount);
                // If a transfer fails, it's better to emit an event and continue
                // rather than reverting the whole transaction, but for simplicity,
                // we'll require all transfers to succeed.
                require(success, "Token transfer to a recipient failed.");
                emit Airdropped(recipient, _amount);
            }
        }
    }

    /**
     * @dev Allows the owner to withdraw any remaining tokens from the contract.
     * This is useful for recovering tokens that were not distributed or sent in excess.
     */
    function withdrawRemainingTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            bool success = token.transfer(owner, balance);
            require(success, "Failed to withdraw remaining tokens.");
        }
    }

    /**
     * @dev Returns the current token balance of the airdrop contract.
     */
    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Allows the owner to transfer ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        owner = newOwner;
    }
}
