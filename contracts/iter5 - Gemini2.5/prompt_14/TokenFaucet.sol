// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20
 * @dev Minimal interface for an ERC20 token.
 */
interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @param to The address of the recipient.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     * @param account The address of the owner.
     * @return The token balance.
     */
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title TokenFaucet
 * @dev A faucet that dispenses a fixed amount of tokens to users once every 24 hours.
 */
contract TokenFaucet {
    // The ERC20 token that the faucet dispenses.
    IERC20 public immutable token;
    // The fixed amount of tokens to dispense per claim.
    uint256 public immutable claimAmount;
    // The cooldown period between claims (24 hours).
    uint256 public constant COOLDOWN_PERIOD = 24 hours;

    // Mapping from a user's address to the timestamp of their last claim.
    mapping(address => uint256) public lastClaimTime;

    /**
     * @dev Event emitted when a user claims tokens from the faucet.
     * @param user The address of the user who claimed tokens.
     * @param amount The amount of tokens claimed.
     */
    event TokensClaimed(address indexed user, uint256 amount);

    /**
     * @dev Sets up the faucet with the token address and claim amount.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _claimAmount The amount of tokens to dispense in each claim.
     */
    constructor(address _tokenAddress, uint256 _claimAmount) {
        require(_tokenAddress != address(0), "Token address cannot be zero.");
        require(_claimAmount > 0, "Claim amount must be positive.");
        
        token = IERC20(_tokenAddress);
        claimAmount = _claimAmount;
    }

    /**
     * @dev Allows a user to claim tokens from the faucet.
     * - The user must wait for the cooldown period to pass since their last claim.
     * - The faucet must have enough tokens to fulfill the claim.
     */
    function claimTokens() public {
        require(block.timestamp >= lastClaimTime[msg.sender] + COOLDOWN_PERIOD, "You must wait 24 hours between claims.");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet is empty, please try again later.");

        lastClaimTime[msg.sender] = block.timestamp;
        
        emit TokensClaimed(msg.sender, claimAmount);
        
        require(token.transfer(msg.sender, claimAmount), "Token transfer failed.");
    }

    /**
     * @dev Allows the owner to fund the faucet with more tokens.
     * This function is not strictly necessary if funding is done via direct transfers,
     * but it provides a clear interface for adding funds.
     * @param _amount The amount of tokens to add to the faucet.
     */
    function fundFaucet(uint256 _amount) public {
        // This function assumes the caller has approved the faucet to spend their tokens.
        // A simpler approach is to directly transfer tokens to the contract address.
        // This function is included for completeness.
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer to faucet failed.");
    }

    /**
     * @dev Retrieves the timestamp of a user's last claim.
     * @param _user The address of the user.
     * @return The timestamp of the last claim.
     */
    function getLastClaimTime(address _user) public view returns (uint256) {
        return lastClaimTime[_user];
    }

    /**
     * @dev Returns the remaining time until a user can claim again.
     * @param _user The address of the user.
     * @return The remaining cooldown time in seconds.
     */
    function getRemainingCooldown(address _user) public view returns (uint256) {
        uint256 nextClaimTime = lastClaimTime[_user] + COOLDOWN_PERIOD;
        if (block.timestamp >= nextClaimTime) {
            return 0;
        }
        return nextClaimTime - block.timestamp;
    }
}
