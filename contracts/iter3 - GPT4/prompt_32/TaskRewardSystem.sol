// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskRewardSystem {
    struct Task {
        string description;
        uint256 reward;
        bool completed;
        address completer;
    }

    address public owner;
    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed completer, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata description) external payable onlyOwner {
        require(msg.value > 0, "Reward must be > 0");
        tasks[taskCount] = Task({
            description: description,
            reward: msg.value,
            completed: false,
            completer: address(0)
        });
        emit TaskCreated(taskCount, description, msg.value);
        taskCount++;
    }

    function completeTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        require(!task.completed, "Task already completed");
        require(task.reward > 0, "Invalid task");
        task.completed = true;
        task.completer = msg.sender;
        payable(msg.sender).transfer(task.reward);
        emit TaskCompleted(taskId, msg.sender, task.reward);
    }

    function getTask(uint256 taskId) external view returns (string memory, uint256, bool, address) {
        Task storage task = tasks[taskId];
        return (task.description, task.reward, task.completed, task.completer);
    }
}
