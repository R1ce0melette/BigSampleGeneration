// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;
    struct Task {
        string description;
        uint256 reward;
        bool completed;
        address completer;
    }
    Task[] public tasks;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addTask(string calldata description, uint256 reward) external onlyOwner payable {
        require(msg.value == reward, "Reward must be funded");
        tasks.push(Task(description, reward, false, address(0)));
    }

    function completeTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        require(!task.completed, "Already completed");
        task.completed = true;
        task.completer = msg.sender;
        payable(msg.sender).transfer(task.reward);
    }

    function getTask(uint256 taskId) external view returns (string memory, uint256, bool, address) {
        Task storage task = tasks[taskId];
        return (task.description, task.reward, task.completed, task.completer);
    }

    function getTaskCount() external view returns (uint256) {
        return tasks.length;
    }
}
