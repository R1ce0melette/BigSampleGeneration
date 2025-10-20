// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;

    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool isCompleted;
        address completedBy;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public taskCounter;

    event TaskCreated(uint256 indexed id, string description, uint256 reward);
    event TaskCompleted(uint256 indexed id, address indexed completedBy);

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory _description, uint256 _reward) public payable {
        require(msg.sender == owner, "Only the owner can create tasks.");
        require(msg.value == _reward, "Must fund the task with the specified reward amount.");
        
        taskCounter++;
        tasks[taskCounter] = Task({
            id: taskCounter,
            description: _description,
            reward: _reward,
            isCompleted: false,
            completedBy: address(0)
        });

        emit TaskCreated(taskCounter, _description, _reward);
    }

    function completeTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(_taskId > 0 && _taskId <= taskCounter, "Task does not exist.");
        require(!task.isCompleted, "Task has already been completed.");

        task.isCompleted = true;
        task.completedBy = msg.sender;

        payable(msg.sender).transfer(task.reward);

        emit TaskCompleted(_taskId, msg.sender);
    }
}
