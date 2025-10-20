// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskReward {
    address public owner;

    struct Task {
        uint id;
        string description;
        uint256 reward;
        bool isActive;
        bool isCompleted;
        address completer;
    }

    Task[] public tasks;
    uint public taskCount;

    event TaskCreated(uint id, string description, uint256 reward);
    event TaskCompleted(uint id, address indexed completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory _description, uint256 _reward) public onlyOwner {
        require(_reward > 0, "Reward must be greater than zero.");
        taskCount++;
        tasks.push(Task(taskCount, _description, _reward, true, false, address(0)));
        emit TaskCreated(taskCount, _description, _reward);
    }

    function completeTask(uint _taskId) public {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        Task storage task = tasks[_taskId - 1];
        require(task.isActive, "Task is not active.");
        require(!task.isCompleted, "Task is already completed.");
        require(address(this).balance >= task.reward, "Contract does not have enough funds to pay the reward.");

        task.isCompleted = true;
        task.completer = msg.sender;
        task.isActive = false;

        payable(msg.sender).transfer(task.reward);
        emit TaskCompleted(_taskId, msg.sender);
    }
    
    function deposit() public payable onlyOwner {
        // To fund the contract with ETH for rewards
    }

    function getTask(uint _taskId) public view returns (uint, string memory, uint256, bool, bool, address) {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        Task storage task = tasks[_taskId - 1];
        return (task.id, task.description, task.reward, task.isActive, task.isCompleted, task.completer);
    }
}
