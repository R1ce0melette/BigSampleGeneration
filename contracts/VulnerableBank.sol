// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title VulnerableBank
 * @dev A deliberately vulnerable banking contract for security testing
 * Contains multiple security issues for Slither to detect
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;
    address public owner;
    uint256 public totalDeposits;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    // Vulnerable: No access control modifier
    function setOwner(address _newOwner) public {
        owner = _newOwner;
    }
    
    function deposit() public payable {
        require(msg.value > 0, "Must deposit positive amount");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // Vulnerable: Reentrancy attack possible
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // External call before state update (reentrancy vulnerability)
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] -= _amount;
        totalDeposits -= _amount;
        emit Withdrawal(msg.sender, _amount);
    }
    
    // Vulnerable: Integer overflow/underflow (if using older Solidity)
    function unsafeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b; // Could overflow
    }
    
    // Vulnerable: Unprotected selfdestruct
    function destroy() public {
        selfdestruct(payable(owner));
    }
    
    // Vulnerable: Timestamp dependence
    function isLuckyTime() public view returns (bool) {
        return block.timestamp % 2 == 0;
    }
    
    // Vulnerable: Weak randomness using prevrandao
    function randomNumber() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 100;
    }
    
    // Vulnerable: Unchecked low-level call
    function callExternal(address _target, bytes memory _data) public returns (bool) {
        (bool success, ) = _target.call(_data);
        return success; // Doesn't check return value properly
    }
    
    receive() external payable {
        deposit();
    }
}
