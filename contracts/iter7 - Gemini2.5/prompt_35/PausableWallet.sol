// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PausableWallet
 * @dev A wallet contract that allows the owner to pause and unpause ETH transfers.
 * When paused, no deposits or withdrawals can be made.
 */
contract PausableWallet {
    // The address of the contract owner.
    address public owner;

    // Flag to indicate if the contract is paused.
    bool public isPaused;

    // Mapping from user address to their balance.
    mapping(address => uint256) public balances;

    /**
     * @dev Emitted when the contract is paused.
     * @param account The address of the owner who paused the contract.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the contract is unpaused.
     * @param account The address of the owner who unpaused the contract.
     */
    event Unpaused(address account);

    /**
     * @dev Emitted when a user deposits ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH deposited.
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "PausableWallet: Caller is not the owner.");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "PausableWallet: Contract is currently paused.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isPaused = false;
    }

    /**
     * @dev Pauses the contract. Only the owner can call this.
     */
    function pause() public onlyOwner {
        require(!isPaused, "PausableWallet: Contract is already paused.");
        isPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only the owner can call this.
     */
    function unpause() public onlyOwner {
        require(isPaused, "PausableWallet: Contract is not paused.");
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows a user to deposit ETH into their wallet.
     * This function is blocked when the contract is paused.
     */
    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their entire balance.
     * This function is blocked when the contract is paused.
     */
    function withdraw() public whenNotPaused {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw.");

        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Returns the current balance of the calling user.
     * @return The balance of msg.sender.
     */
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
