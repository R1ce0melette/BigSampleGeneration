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
        require(bytes(description).length > 0, "Description required");
        require(reward > 0, "Reward must be positive");
        require(msg.value == reward, "Send reward amount");
        tasks.push(Task({
            description: description,
            reward: reward,
            completer: address(0),
            completed: false
        }));
        emit TaskCreated(tasks.length - 1, description, reward);
    }

    function completeTask(uint256 id) external {
        require(id < tasks.length, "Invalid task");
        Task storage t = tasks[id];
        require(!t.completed, "Already completed");
        t.completed = true;
        t.completer = msg.sender;
        payable(msg.sender).transfer(t.reward);
        emit TaskCompleted(id, msg.sender);
    }

    function getTask(uint256 id) external view returns (string memory, uint256, address, bool) {
        require(id < tasks.length, "Invalid task");
        Task storage t = tasks[id];
        return (t.description, t.reward, t.completer, t.completed);
    }

    function getTaskCount() external view returns (uint256) {
        return tasks.length;
    }
}
