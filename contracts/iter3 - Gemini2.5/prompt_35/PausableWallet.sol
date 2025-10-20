// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PausableWallet
 * @dev A wallet contract that allows the owner to pause and resume all ETH transfers
 * as a safety mechanism. Users can deposit and withdraw when the contract is not paused.
 */
contract PausableWallet {
    address public owner;
    bool public isPaused;
    mapping(address => uint256) public balances;

    /**
     * @dev Emitted when the contract's paused state is changed.
     * @param isPaused The new paused state of the contract.
     */
    event PausedStateChanged(bool isPaused);

    /**
     * @dev Emitted when a user deposits ETH.
     * @param user The address of the depositor.
     * @param amount The amount deposited.
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws ETH.
     * @param user The address of the withdrawer.
     * @param amount The amount withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is currently paused.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isPaused = false;
    }

    /**
     * @dev Pauses all transfer functions in the contract.
     * Only the owner can call this.
     */
    function pause() public onlyOwner {
        require(!isPaused, "Contract is already paused.");
        isPaused = true;
        emit PausedStateChanged(true);
    }

    /**
     * @dev Resumes all transfer functions in the contract.
     * Only the owner can call this.
     */
    function resume() public onlyOwner {
        require(isPaused, "Contract is not paused.");
        isPaused = false;
        emit PausedStateChanged(false);
    }

    /**
     * @dev Allows a user to deposit ETH into their balance.
     * This function is pausable.
     */
    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw a specified amount from their balance.
     * This function is pausable.
     * @param _amount The amount to withdraw.
     */
    function withdraw(uint256 _amount) public whenNotPaused {
        require(balances[msg.sender] >= _amount, "Insufficient balance.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @dev Returns the balance of a specific user.
     */
    function getUserBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    /**
     * @dev Returns the total balance of the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the owner to transfer ownership of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        owner = _newOwner;
    }

    // Fallback to receive ETH
    receive() external payable whenNotPaused {
        deposit();
    }
}
