// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;
    struct Task {
        string description;
        uint256 reward;
        bool completed;
        address worker;
    }

    uint256 public nextTaskId;
    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 indexed id, string description, uint256 reward);
    event TaskCompleted(uint256 indexed id, address indexed worker);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata description, uint256 reward) external onlyOwner payable {
        require(msg.value == reward, "Reward must be funded");
        tasks[nextTaskId] = Task(description, reward, false, address(0));
        emit TaskCreated(nextTaskId, description, reward);
        nextTaskId++;
    }

    function completeTask(uint256 taskId) external {
        Task storage t = tasks[taskId];
        require(!t.completed, "Already completed");
        t.completed = true;
        t.worker = msg.sender;
        payable(msg.sender).transfer(t.reward);
        emit TaskCompleted(taskId, msg.sender);
    }

    function getTask(uint256 taskId) external view returns (string memory, uint256, bool, address) {
        Task storage t = tasks[taskId];
        return (t.description, t.reward, t.completed, t.worker);
    }
}
