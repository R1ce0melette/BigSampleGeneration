// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaskRewardSystem is Ownable {
    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool isActive;
        bool isCompleted;
        address completedBy;
    }

    Task[] public tasks;
    uint256 public taskCount;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed user);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Allows the owner to create a new task with a reward.
     * @param _description A description of the task.
     * @param _reward The ETH reward for completing the task.
     */
    function createTask(string memory _description, uint256 _reward) public onlyOwner {
        require(bytes(_description).length > 0, "Description cannot be empty.");
        require(_reward > 0, "Reward must be greater than zero.");
        
        taskCount++;
        tasks.push(Task({
            id: taskCount,
            description: _description,
            reward: _reward,
            isActive: true,
            isCompleted: false,
            completedBy: address(0)
        }));

        emit TaskCreated(taskCount, _description, _reward);
    }

    /**
     * @dev Allows a user to claim completion of a task.
     *      In a real system, this would likely involve some verification.
     *      Here, we assume the first person to claim it completes it.
     * @param _taskId The ID of the task to complete.
     */
    function completeTask(uint256 _taskId) public {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        Task storage task = tasks[_taskId - 1];
        require(task.isActive, "Task is not active.");
        require(!task.isCompleted, "Task has already been completed.");
        
        // The contract must be funded with enough ETH to pay the reward.
        require(address(this).balance >= task.reward, "Contract has insufficient funds for reward.");

        task.isCompleted = true;
        task.completedBy = msg.sender;
        task.isActive = false; // A task can only be completed once

        payable(msg.sender).transfer(task.reward);
        emit TaskCompleted(_taskId, msg.sender);
    }

    /**
     * @dev Allows the owner to deposit ETH into the contract to fund rewards.
     */
    function deposit() public payable onlyOwner {
        // This function simply allows the owner to send ETH to the contract.
    }

    /**
     * @dev Retrieves the details of a specific task.
     * @param _taskId The ID of the task.
     * @return The task's description, reward, completion status, and who completed it.
     */
    function getTask(uint256 _taskId) public view returns (string memory, uint256, bool, address) {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        Task storage task = tasks[_taskId - 1];
        return (task.description, task.reward, task.isCompleted, task.completedBy);
    }
}
