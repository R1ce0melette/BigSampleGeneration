// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TaskRewardSystem
 * @dev A contract where a manager can create tasks with ETH rewards,
 * and users can claim rewards upon task completion.
 */
contract TaskRewardSystem {
    address public manager;
    uint256 public taskCounter;

    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool isActive;
        mapping(address => bool) isCompletedBy;
    }

    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed user);
    event TaskDeactivated(uint256 indexed taskId);

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can call this function.");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    /**
     * @dev Creates a new task with a specified reward.
     * The manager must send enough ETH to fund the reward.
     * @param _description A description of the task.
     */
    function createTask(string memory _description) external payable onlyManager {
        require(bytes(_description).length > 0, "Description cannot be empty.");
        require(msg.value > 0, "Reward must be greater than zero.");

        taskCounter++;
        Task storage newTask = tasks[taskCounter];
        newTask.id = taskCounter;
        newTask.description = _description;
        newTask.reward = msg.value;
        newTask.isActive = true;

        emit TaskCreated(taskCounter, _description, msg.value);
    }

    /**
     * @dev Allows the manager to approve task completion for a user, sending them the reward.
     * @param _taskId The ID of the completed task.
     * @param _user The address of the user who completed the task.
     */
    function completeTask(uint256 _taskId, address payable _user) external onlyManager {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist.");
        require(task.isActive, "Task is not active.");
        require(!task.isCompletedBy[_user], "User has already completed this task.");
        require(address(this).balance >= task.reward, "Contract has insufficient funds for reward.");

        task.isCompletedBy[_user] = true;
        (bool success, ) = _user.call{value: task.reward}("");
        require(success, "Reward transfer failed.");

        emit TaskCompleted(_taskId, _user);
    }

    /**
     * @dev Deactivates a task so no more rewards can be claimed.
     * The manager can then withdraw the remaining funds for that task.
     * @param _taskId The ID of the task to deactivate.
     */
    function deactivateTask(uint256 _taskId) external onlyManager {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist.");
        require(task.isActive, "Task is already inactive.");

        task.isActive = false;
        emit TaskDeactivated(_taskId);
    }
    
    /**
     * @dev Allows the manager to withdraw the reward from a deactivated task
     * if it hasn't been paid out.
     * @param _taskId The ID of the task.
     */
    function withdrawFromTask(uint256 _taskId) external onlyManager {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist.");
        require(!task.isActive, "Task must be inactive to withdraw.");
        require(task.reward > 0, "No reward to withdraw from this task.");

        uint256 amount = task.reward;
        task.reward = 0; // Prevent re-entrancy and double withdrawal

        (bool success, ) = payable(manager).call{value: amount}("");
        require(success, "Withdrawal failed.");
    }

    function getTask(uint256 _taskId) external view returns (string memory, uint256, bool) {
        Task storage task = tasks[_taskId];
        return (task.description, task.reward, task.isActive);
    }
}
