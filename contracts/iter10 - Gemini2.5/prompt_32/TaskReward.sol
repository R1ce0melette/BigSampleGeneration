// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;

    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool completed;
        address completer;
    }

    Task[] public tasks;
    uint256 public taskCount;

    event TaskCreated(uint256 id, string description, uint256 reward);
    event TaskCompleted(uint256 id, address indexed completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory _description, uint256 _reward) public payable onlyOwner {
        require(msg.value == _reward, "Reward must be sent with task creation.");
        taskCount++;
        tasks.push(Task(taskCount, _description, _reward, false, address(0)));
        emit TaskCreated(taskCount, _description, _reward);
    }

    function completeTask(uint256 _taskId) public {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        Task storage task = tasks[_taskId - 1];
        require(!task.completed, "Task is already completed.");

        task.completed = true;
        task.completer = msg.sender;
        
        payable(msg.sender).transfer(task.reward);
        emit TaskCompleted(_taskId, msg.sender);
    }

    function getTask(uint256 _taskId) public view returns (uint256, string memory, uint256, bool, address) {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        Task storage task = tasks[_taskId - 1];
        return (task.id, task.description, task.reward, task.completed, task.completer);
    }
}
