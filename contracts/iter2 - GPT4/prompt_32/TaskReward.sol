// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;
    uint256 public nextTaskId;

    struct Task {
        string description;
        uint256 reward;
        bool completed;
        address completer;
    }

    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata description) external payable onlyOwner {
        require(msg.value > 0, "No reward");
        tasks[nextTaskId] = Task(description, msg.value, false, address(0));
        emit TaskCreated(nextTaskId, description, msg.value);
        nextTaskId++;
    }

    function completeTask(uint256 taskId) external {
        Task storage t = tasks[taskId];
        require(!t.completed, "Already completed");
        t.completed = true;
        t.completer = msg.sender;
        payable(msg.sender).transfer(t.reward);
        emit TaskCompleted(taskId, msg.sender);
    }

    function getTask(uint256 taskId) external view returns (string memory, uint256, bool, address) {
        Task storage t = tasks[taskId];
        return (t.description, t.reward, t.completed, t.completer);
    }
}
