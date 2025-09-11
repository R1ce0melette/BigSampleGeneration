// Write a Solidity ^0.8.25 contract for a basic ERC-20 token with mint and burn functions. Include events for transfers and total supply tracking.
pragma solidity ^0.8.25;

contract BasicERC20 {
	string public name = "BasicERC20";
	string public symbol = "BERC";
	uint8 public decimals = 18;
	uint256 public totalSupply;

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event TotalSupplyUpdated(uint256 newTotalSupply);

	address public owner;

	modifier onlyOwner() {
		require(msg.sender == owner, "Not owner");
		_;
	}

	constructor() {
		owner = msg.sender;
	}

	function transfer(address to, uint256 value) public returns (bool) {
		require(balanceOf[msg.sender] >= value, "Insufficient balance");
		balanceOf[msg.sender] -= value;
		balanceOf[to] += value;
		emit Transfer(msg.sender, to, value);
		return true;
	}

	function approve(address spender, uint256 value) public returns (bool) {
		allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) public returns (bool) {
		require(balanceOf[from] >= value, "Insufficient balance");
		require(allowance[from][msg.sender] >= value, "Allowance exceeded");
		balanceOf[from] -= value;
		balanceOf[to] += value;
		allowance[from][msg.sender] -= value;
		emit Transfer(from, to, value);
		return true;
	}

	function mint(address to, uint256 value) public onlyOwner {
		balanceOf[to] += value;
		totalSupply += value;
		emit Transfer(address(0), to, value);
		emit TotalSupplyUpdated(totalSupply);
	}

	function burn(address from, uint256 value) public onlyOwner {
		require(balanceOf[from] >= value, "Insufficient balance");
		balanceOf[from] -= value;
		totalSupply -= value;
		emit Transfer(from, address(0), value);
		emit TotalSupplyUpdated(totalSupply);
	}
}