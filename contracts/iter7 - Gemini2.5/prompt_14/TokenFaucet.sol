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
 * @title TokenFaucet
 * @dev A faucet that dispenses a fixed amount of ERC20 tokens to users once every 24 hours.
 */
contract TokenFaucet {
    // The ERC20 token that the faucet dispenses.
    IERC20 public immutable token;

    // The fixed amount of tokens to dispense per claim.
    uint256 public immutable claimAmount;

    // The cooldown period in seconds (24 hours).
    uint256 public constant COOLDOWN_PERIOD = 24 hours;

    // Mapping to track the last time a user claimed tokens.
    mapping(address => uint256) public lastClaimed;

    /**
     * @dev Emitted when a user claims tokens from the faucet.
     * @param user The address of the user who claimed tokens.
     * @param amount The amount of tokens claimed.
     */
    event TokensClaimed(address indexed user, uint256 amount);

    /**
     * @dev Sets up the faucet with the token address and the claim amount.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _claimAmount The amount of tokens to be dispensed on each claim.
     */
    constructor(address _tokenAddress, uint256 _claimAmount) {
        require(_tokenAddress != address(0), "Token address cannot be the zero address.");
        require(_claimAmount > 0, "Claim amount must be greater than zero.");
        token = IERC20(_tokenAddress);
        claimAmount = _claimAmount;
    }

    /**
     * @dev Allows a user to claim tokens from the faucet.
     * A user can only claim once every 24 hours.
     */
    function claim() public {
        require(block.timestamp >= lastClaimed[msg.sender] + COOLDOWN_PERIOD, "You must wait 24 hours between claims.");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet is empty or has insufficient funds.");

        lastClaimed[msg.sender] = block.timestamp;

        bool sent = token.transfer(msg.sender, claimAmount);
        require(sent, "Failed to transfer tokens.");

        emit TokensClaimed(msg.sender, claimAmount);
    }

    /**
     * @dev Returns the time remaining until the user can claim again.
     * @param _user The address of the user to check.
     * @return The time in seconds until the next claim is available.
     */
    function timeUntilNextClaim(address _user) public view returns (uint256) {
        uint256 nextClaimTime = lastClaimed[_user] + COOLDOWN_PERIOD;
        if (block.timestamp >= nextClaimTime) {
            return 0;
        }
        return nextClaimTime - block.timestamp;
    }
}
