// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PausableWallet is Pausable, Ownable {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Allows users to deposit ETH. This action is not pausable.
     */
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw their ETH. This action can be paused by the owner.
     *      The `whenNotPaused` modifier ensures this function can only be called when the contract is not paused.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @dev Allows the owner to pause the contract's withdraw functionality.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Allows the owner to unpause the contract's withdraw functionality.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Returns the balance of the calling user.
     */
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
