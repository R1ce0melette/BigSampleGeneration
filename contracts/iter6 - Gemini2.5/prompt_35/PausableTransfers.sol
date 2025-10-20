// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PausableTransfers {
    address public owner;
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);
    event Transferred(address indexed from, address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
        _paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is currently paused.");
        _;
    }

    function pause() public onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    function resume() public onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }
    
    function isPaused() public view returns (bool) {
        return _paused;
    }

    // Example function that can be paused
    function transfer(address payable _to, uint256 _amount) public payable whenNotPaused {
        // This is a simple example. In a real contract, you'd likely be transferring from a user's balance.
        // Here we just check if the sent value matches the amount.
        require(msg.value == _amount, "Sent value must match the transfer amount.");
        _to.transfer(_amount);
        emit Transferred(msg.sender, _to, _amount);
    }
    
    // The owner can withdraw funds even when paused
    function ownerWithdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
