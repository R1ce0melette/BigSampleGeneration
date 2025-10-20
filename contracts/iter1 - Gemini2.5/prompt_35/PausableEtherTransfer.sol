// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor() {
        _paused = false;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract PausableEtherTransfer is Ownable, Pausable {

    event EtherTransferred(address indexed from, address indexed to, uint256 amount);
    event EtherReceived(address indexed from, uint256 amount);

    function transfer(address payable _to, uint256 _amount) public payable whenNotPaused {
        require(msg.sender.balance >= _amount, "Insufficient balance for transfer.");
        require(msg.value == _amount, "The sent ETH amount must match the transfer amount.");
        
        _to.transfer(_amount);
        
        emit EtherTransferred(msg.sender, _to, _amount);
    }

    // A function to simply send ETH to this contract to be held.
    receive() external payable whenNotPaused {
        emit EtherReceived(msg.sender, msg.value);
    }
    
    // A function for the owner to withdraw ETH from the contract.
    function withdraw(uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Contract has insufficient balance.");
        payable(owner()).transfer(_amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
