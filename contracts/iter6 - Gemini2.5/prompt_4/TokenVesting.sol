// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenVesting {
    address public beneficiary;
    uint256 public startTimestamp;
    uint256 public duration;
    uint256 public totalTokens;
    uint256 public releasedTokens;
    IERC20 public token;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(
        address _beneficiary,
        uint256 _durationInSeconds,
        address _tokenAddress
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_durationInSeconds > 0, "Duration must be greater than 0");
        require(_tokenAddress != address(0), "Token address cannot be zero address");

        beneficiary = _beneficiary;
        startTimestamp = block.timestamp;
        duration = _durationInSeconds;
        token = IERC20(_tokenAddress);
    }
    
    function setTotalVestingTokens(uint256 _totalTokens) external {
        // This function is called once by the deployer after transferring tokens to the contract
        require(totalTokens == 0, "Total vesting amount already set.");
        totalTokens = _totalTokens;
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTimestamp) {
            return 0;
        }
        
        uint256 elapsedTime = block.timestamp - startTimestamp;
        if (elapsedTime >= duration) {
            return totalTokens;
        }

        return (totalTokens * elapsedTime) / duration;
    }

    function release() public {
        uint256 releasableAmount = vestedAmount() - releasedTokens;
        require(releasableAmount > 0, "No tokens to release");

        releasedTokens += releasableAmount;
        token.transfer(beneficiary, releasableAmount);

        emit TokensReleased(beneficiary, releasableAmount);
    }
}
