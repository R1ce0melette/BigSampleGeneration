// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TipJar
 * @dev A simple contract that allows users to send ETH tips to a creator.
 * The contract tracks the total tips received and allows the creator to withdraw them.
 */
contract TipJar {
    address payable public creator;
    uint256 public totalTipsReceived;

    /**
     * @dev Emitted when a tip is sent to the creator.
     * @param tipper The address of the user who sent the tip.
     * @param amount The amount of the tip in wei.
     */
    event Tipped(address indexed tipper, uint256 amount);

    /**
     * @dev Emitted when the creator withdraws the collected tips.
     * @param amount The total amount withdrawn.
     */
    event Withdrawn(uint256 amount);

    /**
     * @dev Modifier to ensure that only the creator can call a function.
     */
    modifier onlyCreator() {
        require(msg.sender == creator, "Only the creator can perform this action.");
        _;
    }

    /**
     * @dev Sets up the TipJar with the creator's address.
     * @param _creator The address of the creator who will receive the tips.
     */
    constructor(address payable _creator) {
        require(_creator != address(0), "Creator address cannot be the zero address.");
        creator = _creator;
    }

    /**
     * @dev Allows any user to send a tip to the creator.
     * The function must be called with a value (ETH) to be tipped.
     */
    function tip() public payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        
        totalTipsReceived += msg.value;
        emit Tipped(msg.sender, msg.value);
    }

    /**
     * @dev Allows the creator to withdraw the entire balance of the tip jar.
     */
    function withdraw() public onlyCreator {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw.");

        (bool success, ) = creator.call{value: balance}("");
        require(success, "Withdrawal failed.");

        emit Withdrawn(balance);
    }

    /**
     * @dev Returns the current balance of the tip jar.
     * @return The total amount of ETH held by the contract.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the current creator to transfer the ownership of the tip jar to a new creator.
     * @param _newCreator The address of the new creator.
     */
    function changeCreator(address payable _newCreator) public onlyCreator {
        require(_newCreator != address(0), "New creator address cannot be the zero address.");
        creator = _newCreator;
    }

    // Fallback function to receive ETH directly without calling a function.
    receive() external payable {
        tip();
    }
}
