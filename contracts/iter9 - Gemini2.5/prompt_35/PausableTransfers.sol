// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PausableTransfers {
    address public owner;
    bool public isPaused;

    event Paused();
    event Unpaused();
    event Transferred(address indexed from, address indexed to, uint256 amount);

    modifier whenNotPaused() {
        require(!isPaused, "Contract is currently paused.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isPaused = false;
    }

    function pause() public onlyOwner whenNotPaused {
        isPaused = true;
        emit Paused();
    }

    function unpause() public onlyOwner {
        require(isPaused, "Contract is not paused.");
        isPaused = false;
        emit Unpaused();
    }

    function transfer(address payable _to, uint256 _amount) public payable whenNotPaused {
        require(msg.value >= _amount, "Insufficient ETH sent for the transfer.");
        _to.transfer(_amount);
        emit Transferred(msg.sender, _to, _amount);
        
        // Return any excess ETH sent
        if (msg.value > _amount) {
            payable(msg.sender).transfer(msg.value - _amount);
        }
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
