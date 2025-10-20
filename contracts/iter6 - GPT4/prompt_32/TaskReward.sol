// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    struct Task {
        string description;
        uint256 reward;
        address completer;
        bool completed;
    }

    Task[] public tasks;
    address public owner;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata description, uint256 reward) external payable onlyOwner {
        require(msg.value == reward, "ETH must match reward");
        tasks.push(Task({
            description: description,
            reward: reward,
            completer: address(0),
            completed: false
        }));
        emit TaskCreated(tasks.length - 1, description, reward);
    }

    function completeTask(uint256 taskId) external {
        require(taskId < tasks.length, "Invalid taskId");
        Task storage t = tasks[taskId];
        require(!t.completed, "Already completed");
        t.completed = true;
        t.completer = msg.sender;
        (bool sent, ) = msg.sender.call{value: t.reward}("");
        require(sent, "Reward failed");
        emit TaskCompleted(taskId, msg.sender);
    }

    function getTask(uint256 taskId) external view returns (string memory, uint256, address, bool) {
        require(taskId < tasks.length, "Invalid taskId");
        Task storage t = tasks[taskId];
        return (t.description, t.reward, t.completer, t.completed);
    }

    function getTaskCount() external view returns (uint256) {
        return tasks.length;
    }
}
