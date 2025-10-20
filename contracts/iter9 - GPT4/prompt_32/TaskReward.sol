// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    struct Task {
        string description;
        uint256 reward;
        address completer;
        bool completed;
    }

    address public owner;
    Task[] public tasks;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata description) external payable onlyOwner {
        require(msg.value > 0, "No reward");
        tasks.push(Task({
            description: description,
            reward: msg.value,
            completer: address(0),
            completed: false
        }));
        emit TaskCreated(tasks.length - 1, description, msg.value);
    }

    function completeTask(uint256 taskId) external {
        Task storage t = tasks[taskId];
        require(!t.completed, "Already completed");
        t.completed = true;
        t.completer = msg.sender;
        payable(msg.sender).transfer(t.reward);
        emit TaskCompleted(taskId, msg.sender);
    }

    function getTask(uint256 taskId) external view returns (string memory, uint256, address, bool) {
        Task storage t = tasks[taskId];
        return (t.description, t.reward, t.completer, t.completed);
    }

    function getTaskCount() external view returns (uint256) {
        return tasks.length;
    }
}
