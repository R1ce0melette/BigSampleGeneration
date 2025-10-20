// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20
 * @dev Minimal interface for the ERC20 standard.
 */
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title TokenAirdrop
 * @dev A contract to perform a token airdrop to a list of addresses.
 */
contract TokenAirdrop {
    // The address of the contract owner who can initiate the airdrop.
    address public owner;

    // The ERC20 token to be airdropped.
    IERC20 public immutable token;

    /**
     * @dev Emitted when tokens are airdropped to a recipient.
     * @param recipient The address that received the tokens.
     * @param amount The amount of tokens airdropped.
     */
    event Airdropped(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "TokenAirdrop: Caller is not the owner.");
        _;
    }

    /**
     * @dev Sets up the contract with the token to be airdropped.
     * @param _tokenAddress The address of the ERC20 token contract.
     */
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token address cannot be the zero address.");
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Performs the airdrop to a list of recipients with a specified amount for each.
     * The lengths of the `_recipients` and `_amounts` arrays must be equal.
     * @param _recipients An array of addresses to receive the airdrop.
     * @param _amounts An array of token amounts to be sent to each recipient.
     */
    function airdrop(address[] memory _recipients, uint256[] memory _amounts) public onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must have the same length.");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance in the contract for the airdrop.");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Cannot airdrop to the zero address.");
            bool sent = token.transfer(_recipients[i], _amounts[i]);
            if (sent) {
                emit Airdropped(_recipients[i], _amounts[i]);
            }
        }
    }

    /**
     * @dev Allows the owner to withdraw any remaining tokens from the contract.
     * This is useful if there are leftover tokens after an airdrop or if tokens were sent by mistake.
     */
    function withdrawRemainingTokens() public onlyOwner {
        uint256 remainingBalance = token.balanceOf(address(this));
        if (remainingBalance > 0) {
            bool sent = token.transfer(owner, remainingBalance);
            require(sent, "Failed to withdraw remaining tokens.");
        }
    }
}
