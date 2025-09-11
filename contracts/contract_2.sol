// Implement a Solidity ^0.8.25 contract for a time-locked wallet that holds ETH. Only the owner can withdraw after a specified unlock time.

pragma solidity ^0.8.25;

contract TimeLockedWallet {
    address public owner;
    uint256 public unlockTime;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    constructor(uint256 _unlockTime) {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the owner");
        require(block.timestamp >= unlockTime, "Funds are still locked");
        
        uint256 balance = address(this).balance;
        emit Withdrawal(msg.sender, balance);
        payable(owner).transfer(balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}