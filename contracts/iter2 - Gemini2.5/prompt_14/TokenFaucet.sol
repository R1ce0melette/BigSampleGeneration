// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFaucet is Ownable {
    IERC20 public token;
    uint256 public dripAmount = 100 * (10**18); // Default 100 tokens
    uint256 public constant COOLDOWN_PERIOD = 24 hours;

    mapping(address => uint256) public lastClaimed;

    event TokensClaimed(address indexed user, uint256 amount);
    event DripAmountUpdated(uint256 newAmount);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Token address cannot be zero.");
        token = IERC20(_tokenAddress);
    }

    /**
     * @dev Allows a user to claim tokens from the faucet.
     */
    function claimTokens() public {
        require(block.timestamp >= lastClaimed[msg.sender] + COOLDOWN_PERIOD, "You can only claim once every 24 hours.");
        require(token.balanceOf(address(this)) >= dripAmount, "Faucet is empty.");

        lastClaimed[msg.sender] = block.timestamp;
        bool success = token.transfer(msg.sender, dripAmount);
        require(success, "Token transfer failed.");

        emit TokensClaimed(msg.sender, dripAmount);
    }

    /**
     * @dev Allows the owner to set the amount of tokens to be dispensed.
     * @param _newAmount The new amount of tokens for each claim.
     */
    function setDripAmount(uint256 _newAmount) public onlyOwner {
        require(_newAmount > 0, "Drip amount must be greater than zero.");
        dripAmount = _newAmount;
        emit DripAmountUpdated(_newAmount);
    }

    /**
     * @dev Allows the owner to withdraw remaining tokens from the faucet contract.
     */
    function withdrawTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw.");
        bool success = token.transfer(owner(), balance);
        require(success, "Token transfer failed.");
    }

    /**
     * @dev Returns the time when the user can next claim tokens.
     * @param _user The address of the user.
     * @return The timestamp of the next available claim time.
     */
    function nextClaimTime(address _user) public view returns (uint256) {
        return lastClaimed[_user] + COOLDOWN_PERIOD;
    }
}
