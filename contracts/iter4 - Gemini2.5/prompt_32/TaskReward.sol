// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;

    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool isActive;
        bool isCompleted;
    }

    Task[] public tasks;
    uint256 public taskCounter;

    event TaskCreated(uint256 indexed id, string description, uint256 reward);
    event TaskCompleted(uint256 indexed id, address indexed completer);
    event FundsDeposited(address indexed from, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function deposit() public payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function createTask(string memory _description, uint256 _reward) public onlyOwner {
        require(_reward > 0, "Reward must be greater than zero.");
        taskCounter++;
        tasks.push(Task(taskCounter, _description, _reward, true, false));
        emit TaskCreated(taskCounter, _description, _reward);
    }

    function completeTask(uint256 _taskId) public {
        require(_taskId > 0 && _taskId <= taskCounter, "Task does not exist.");
        Task storage task = tasks[_taskId - 1]; // Adjust for 0-based index
        require(task.isActive, "Task is not active.");
        require(!task.isCompleted, "Task has already been completed.");
        require(address(this).balance >= task.reward, "Insufficient contract balance to pay reward.");

        task.isCompleted = true;
        task.isActive = false; // A task can only be completed once

        payable(msg.sender).transfer(task.reward);
        emit TaskCompleted(_taskId, msg.sender);
    }

    function getTask(uint256 _taskId) public view returns (uint256, string memory, uint256, bool, bool) {
        require(_taskId > 0 && _taskId <= taskCounter, "Task does not exist.");
        Task storage task = tasks[_taskId - 1];
        return (task.id, task.description, task.reward, task.isActive, task.isCompleted);
    }
    
    function getTaskCount() public view returns (uint256) {
        return tasks.length;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
