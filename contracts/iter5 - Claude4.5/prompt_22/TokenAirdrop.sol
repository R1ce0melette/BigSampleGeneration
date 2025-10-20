// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenAirdrop {
    address public owner;
    uint256 public airdropCount;
    
    struct Airdrop {
        uint256 id;
        uint256 amountPerAddress;
        uint256 totalAmount;
        uint256 distributedAmount;
        bool isActive;
        uint256 createdTime;
    }
    
    mapping(uint256 => Airdrop) public airdrops;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;
    mapping(uint256 => address[]) public airdropRecipients;
    
    event AirdropCreated(uint256 indexed airdropId, uint256 amountPerAddress, uint256 recipientCount);
    event TokensClaimed(uint256 indexed airdropId, address indexed recipient, uint256 amount);
    event AirdropCancelled(uint256 indexed airdropId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createAirdrop(address[] memory _recipients, uint256 _amountPerAddress) external onlyOwner {
        require(_recipients.length > 0, "No recipients provided");
        require(_amountPerAddress > 0, "Amount must be greater than zero");
        
        uint256 totalRequired = _amountPerAddress * _recipients.length;
        require(address(this).balance >= totalRequired, "Insufficient contract balance");
        
        airdropCount++;
        
        airdrops[airdropCount] = Airdrop({
            id: airdropCount,
            amountPerAddress: _amountPerAddress,
            totalAmount: totalRequired,
            distributedAmount: 0,
            isActive: true,
            createdTime: block.timestamp
        });
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            airdropRecipients[airdropCount].push(_recipients[i]);
        }
        
        emit AirdropCreated(airdropCount, _amountPerAddress, _recipients.length);
    }
    
    function claim(uint256 _airdropId) external {
        require(_airdropId > 0 && _airdropId <= airdropCount, "Airdrop does not exist");
        
        Airdrop storage airdrop = airdrops[_airdropId];
        
        require(airdrop.isActive, "Airdrop is not active");
        require(!hasClaimed[_airdropId][msg.sender], "Already claimed");
        require(isRecipient(_airdropId, msg.sender), "Not eligible for this airdrop");
        
        hasClaimed[_airdropId][msg.sender] = true;
        airdrop.distributedAmount += airdrop.amountPerAddress;
        
        (bool success, ) = payable(msg.sender).call{value: airdrop.amountPerAddress}("");
        require(success, "Transfer failed");
        
        emit TokensClaimed(_airdropId, msg.sender, airdrop.amountPerAddress);
    }
    
    function distributeAll(uint256 _airdropId) external onlyOwner {
        require(_airdropId > 0 && _airdropId <= airdropCount, "Airdrop does not exist");
        
        Airdrop storage airdrop = airdrops[_airdropId];
        require(airdrop.isActive, "Airdrop is not active");
        
        address[] memory recipients = airdropRecipients[_airdropId];
        
        for (uint256 i = 0; i < recipients.length; i++) {
            if (!hasClaimed[_airdropId][recipients[i]]) {
                hasClaimed[_airdropId][recipients[i]] = true;
                airdrop.distributedAmount += airdrop.amountPerAddress;
                
                (bool success, ) = payable(recipients[i]).call{value: airdrop.amountPerAddress}("");
                require(success, "Transfer failed");
                
                emit TokensClaimed(_airdropId, recipients[i], airdrop.amountPerAddress);
            }
        }
    }
    
    function cancelAirdrop(uint256 _airdropId) external onlyOwner {
        require(_airdropId > 0 && _airdropId <= airdropCount, "Airdrop does not exist");
        
        Airdrop storage airdrop = airdrops[_airdropId];
        require(airdrop.isActive, "Airdrop is already cancelled");
        
        airdrop.isActive = false;
        
        emit AirdropCancelled(_airdropId);
    }
    
    function isRecipient(uint256 _airdropId, address _address) public view returns (bool) {
        require(_airdropId > 0 && _airdropId <= airdropCount, "Airdrop does not exist");
        
        address[] memory recipients = airdropRecipients[_airdropId];
        
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == _address) {
                return true;
            }
        }
        
        return false;
    }
    
    function hasUserClaimed(uint256 _airdropId, address _user) external view returns (bool) {
        require(_airdropId > 0 && _airdropId <= airdropCount, "Airdrop does not exist");
        return hasClaimed[_airdropId][_user];
    }
    
    function getAirdropRecipients(uint256 _airdropId) external view returns (address[] memory) {
        require(_airdropId > 0 && _airdropId <= airdropCount, "Airdrop does not exist");
        return airdropRecipients[_airdropId];
    }
    
    function getAirdropInfo(uint256 _airdropId) external view returns (
        uint256 id,
        uint256 amountPerAddress,
        uint256 totalAmount,
        uint256 distributedAmount,
        bool isActive,
        uint256 recipientCount
    ) {
        require(_airdropId > 0 && _airdropId <= airdropCount, "Airdrop does not exist");
        
        Airdrop memory airdrop = airdrops[_airdropId];
        
        return (
            airdrop.id,
            airdrop.amountPerAddress,
            airdrop.totalAmount,
            airdrop.distributedAmount,
            airdrop.isActive,
            airdropRecipients[_airdropId].length
        );
    }
    
    function depositFunds() external payable {
        require(msg.value > 0, "Must deposit a positive amount");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
