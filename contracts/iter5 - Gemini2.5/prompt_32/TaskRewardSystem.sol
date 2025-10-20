// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TaskRewardSystem
 * @dev A contract for a task reward system where users earn ETH for completing tasks.
 */
contract TaskRewardSystem {

    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool isActive;
        bool isCompleted;
    }

    address public owner;
    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed completer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Creates a new task with a specified reward.
     */
    function createTask(string memory _description, uint256 _reward) public onlyOwner {
        require(bytes(_description).length > 0, "Description cannot be empty.");
        require(_reward > 0, "Reward must be positive.");

        uint256 taskId = taskCount;
        tasks[taskId] = Task({
            id: taskId,
            description: _description,
            reward: _reward,
            isActive: true,
            isCompleted: false
        });
        taskCount++;
        emit TaskCreated(taskId, _description, _reward);
    }

    /**
     * @dev Marks a task as completed and sends the reward to the user.
     */
    function completeTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.isActive, "Task is not active.");
        require(!task.isCompleted, "Task has already been completed.");
        require(address(this).balance >= task.reward, "Contract has insufficient funds for reward.");

        task.isCompleted = true;
        task.isActive = false;

        payable(msg.sender).transfer(task.reward);
        emit TaskCompleted(_taskId, msg.sender);
    }
}
