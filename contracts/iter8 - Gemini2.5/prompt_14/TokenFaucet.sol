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
 * @dev A faucet that dispenses a fixed amount of tokens to users once every 24 hours.
 */
contract TokenFaucet {
    address public owner;
    IERC20 public token;
    uint256 public claimAmount;
    uint256 public constant CLAIM_INTERVAL = 24 hours;

    mapping(address => uint256) public lastClaimed;

    event TokensClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    /**
     * @dev Sets the token contract address and the amount to claim.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _claimAmount The amount of tokens to be claimed per user.
     */
    constructor(address _tokenAddress, uint256 _claimAmount) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        claimAmount = _claimAmount;
    }

    /**
     * @dev Allows a user to claim a fixed amount of tokens.
     * A user can only claim once every 24 hours.
     */
    function claimTokens() external {
        require(block.timestamp >= lastClaimed[msg.sender] + CLAIM_INTERVAL, "You can only claim once every 24 hours.");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet does not have enough tokens.");

        lastClaimed[msg.sender] = block.timestamp;
        
        bool success = token.transfer(msg.sender, claimAmount);
        require(success, "Token transfer failed.");

        emit TokensClaimed(msg.sender, claimAmount);
    }

    /**
     * @dev Allows the owner to withdraw remaining tokens from the contract.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance.");
        bool success = token.transfer(owner, _amount);
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev Allows the owner to change the claim amount.
     * @param _newAmount The new amount of tokens to be claimed.
     */
    function setClaimAmount(uint256 _newAmount) external onlyOwner {
        claimAmount = _newAmount;
    }
}
