// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public creator;
    uint256 public totalTips;
    mapping(address => uint256) public tippers;

    event Tipped(address indexed tipper, uint256 amount);
    event Withdrawn(uint256 amount);

    constructor() {
        creator = payable(msg.sender);
    }

    function tip() public payable {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        
        tippers[msg.sender] += msg.value;
        totalTips += msg.value;
        
        emit Tipped(msg.sender, msg.value);
    }

    function withdraw() public {
        require(msg.sender == creator, "Only the creator can withdraw.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw.");
        
        creator.transfer(balance);
        
        emit Withdrawn(balance);
    }

    function getTipperAmount(address _tipper) public view returns (uint256) {
        return tippers[_tipper];
    }
}
