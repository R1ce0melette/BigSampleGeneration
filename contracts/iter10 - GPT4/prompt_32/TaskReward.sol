// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;
    uint256 public nextTaskId;

    struct Task {
        string description;
        uint256 reward;
        address completer;
        bool completed;
    }

    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata description, uint256 reward) external onlyOwner payable {
        require(bytes(description).length > 0, "Description required");
        require(reward > 0, "Reward must be positive");
        require(msg.value == reward, "ETH must match reward");
        tasks[nextTaskId] = Task({
            description: description,
            reward: reward,
            completer: address(0),
            completed: false
        });
        emit TaskCreated(nextTaskId, description, reward);
        nextTaskId++;
    }

    function completeTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        require(!task.completed, "Already completed");
        task.completed = true;
        task.completer = msg.sender;
        payable(msg.sender).transfer(task.reward);
        emit TaskCompleted(taskId, msg.sender);
    }

    function getTask(uint256 taskId) external view returns (string memory, uint256, address, bool) {
        Task storage t = tasks[taskId];
        return (t.description, t.reward, t.completer, t.completed);
    }
}
