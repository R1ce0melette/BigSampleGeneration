// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsWallet {
    uint256 public minimumDeposit;
    mapping(address => uint256) public userDeposits;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event MinimumDepositUpdated(uint256 newMinimum);
    
    constructor(uint256 _minimumDeposit) {
        minimumDeposit = _minimumDeposit;
    }
    
    function deposit() external payable {
        require(msg.value >= minimumDeposit, "Deposit amount is below minimum");
        
        userDeposits[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 _amount) external {
        require(userDeposits[msg.sender] >= _amount, "Insufficient balance");
        
        userDeposits[msg.sender] -= _amount;
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, _amount);
    }
    
    function getBalance() external view returns (uint256) {
        return userDeposits[msg.sender];
    }
    
    function getTotalDeposits(address _user) external view returns (uint256) {
        return userDeposits[_user];
    }
}
