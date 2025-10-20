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
 * @title TokenFaucet
 * @dev A faucet that dispenses a fixed amount of ERC20 tokens to users once every 24 hours.
 */
contract TokenFaucet {
    IERC20 public immutable token;
    address public owner;
    
    uint256 public immutable claimAmount;
    uint256 public constant COOLDOWN_PERIOD = 24 hours;

    // Mapping to store the last time a user claimed tokens
    mapping(address => uint256) public lastClaimTime;

    /**
     * @dev Emitted when a user successfully claims tokens from the faucet.
     * @param user The address of the user who claimed the tokens.
     * @param amount The amount of tokens claimed.
     */
    event TokensClaimed(address indexed user, uint256 amount);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets up the faucet with the token address and the claim amount.
     * @param _tokenAddress The address of the ERC20 token to be dispensed.
     * @param _claimAmount The fixed amount of tokens to be claimed each time.
     */
    constructor(address _tokenAddress, uint256 _claimAmount) {
        require(_tokenAddress != address(0), "Token address cannot be the zero address.");
        require(_claimAmount > 0, "Claim amount must be greater than zero.");
        
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        claimAmount = _claimAmount;
    }

    /**
     * @dev Allows a user to claim tokens from the faucet.
     * A user can only claim once within the cooldown period.
     */
    function claimTokens() public {
        require(block.timestamp >= lastClaimTime[msg.sender] + COOLDOWN_PERIOD, "You can only claim once every 24 hours.");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet is out of tokens.");

        lastClaimTime[msg.sender] = block.timestamp;
        
        bool sent = token.transfer(msg.sender, claimAmount);
        require(sent, "Failed to transfer tokens.");

        emit TokensClaimed(msg.sender, claimAmount);
    }

    /**
     * @dev Allows the owner to fund the faucet with more tokens.
     * This function is not strictly necessary as tokens can be transferred directly
     * to the contract address, but it provides an explicit way to do so.
     */
    function fundFaucet(uint256 _amount) public {
        // This requires the caller to have approved the faucet contract
        // to spend at least `_amount` of their tokens.
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
    }

    /**
     * @dev Allows the owner to withdraw all tokens from the faucet.
     * This is useful in case of emergencies or contract retirement.
     */
    function withdrawTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw.");
        
        bool sent = token.transfer(owner, balance);
        require(sent, "Failed to withdraw tokens.");
    }

    /**
     * @dev Returns the current token balance of the faucet contract.
     */
    function getFaucetBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
