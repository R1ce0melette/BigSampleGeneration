// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;

    enum TaskStatus { Open, InProgress, Completed, Closed }

    struct Task {
        string description;
        uint256 reward;
        address payable worker;
        TaskStatus status;
    }

    Task[] public tasks;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed worker);
    event TaskCompleted(uint256 indexed taskId, address indexed worker, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string calldata _description, uint256 _reward) public onlyOwner {
        require(_reward > 0, "Reward must be greater than zero.");
        tasks.push(Task({
            description: _description,
            reward: _reward,
            worker: payable(address(0)),
            status: TaskStatus.Open
        }));
        emit TaskCreated(tasks.length - 1, _description, _reward);
    }

    function startTask(uint256 _taskId) public {
        require(_taskId < tasks.length, "Task does not exist.");
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "Task is not open.");

        task.worker = payable(msg.sender);
        task.status = TaskStatus.InProgress;
        emit TaskAssigned(_taskId, msg.sender);
    }

    function completeTask(uint256 _taskId) public onlyOwner {
        require(_taskId < tasks.length, "Task does not exist.");
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.InProgress, "Task is not in progress.");
        require(address(this).balance >= task.reward, "Contract does not have enough funds to pay the reward.");

        task.status = TaskStatus.Completed;
        task.worker.transfer(task.reward);
        emit TaskCompleted(_taskId, task.worker, task.reward);
    }
    
    function fundContract() public payable onlyOwner {
        // Allows the owner to fund the contract to pay for task rewards.
    }

    function getTask(uint256 _taskId) public view returns (string memory, uint256, address, TaskStatus) {
        require(_taskId < tasks.length, "Task does not exist.");
        Task storage task = tasks[_taskId];
        return (task.description, task.reward, task.worker, task.status);
    }
}
