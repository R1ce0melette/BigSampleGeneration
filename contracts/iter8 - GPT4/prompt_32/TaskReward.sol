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

    event TaskCreated(uint256 indexed id, string description, uint256 reward);
    event TaskCompleted(uint256 indexed id, address indexed completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata description, uint256 reward) external payable onlyOwner {
        require(msg.value == reward, "ETH must match reward");
        tasks.push(Task(description, reward, address(0), false));
        emit TaskCreated(tasks.length - 1, description, reward);
    }

    function completeTask(uint256 id) external {
        require(id < tasks.length, "Invalid task");
        Task storage t = tasks[id];
        require(!t.completed, "Already completed");
        t.completed = true;
        t.completer = msg.sender;
        (bool sent, ) = msg.sender.call{value: t.reward}("");
        require(sent, "Reward failed");
        emit TaskCompleted(id, msg.sender);
    }

    function getTasks() external view returns (Task[] memory) {
        return tasks;
    }
}
