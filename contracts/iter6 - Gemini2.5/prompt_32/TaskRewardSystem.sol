// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TaskRewardSystem
 * @dev A contract for a simple task reward system. The owner can create tasks,
 * and users can claim rewards after the owner verifies task completion.
 */
contract TaskRewardSystem {
    address public owner;

    // Struct to represent a task.
    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool isActive;
    }

    // Counter for generating unique task IDs.
    uint256 private _taskIds;

    // Mapping from task ID to the Task struct.
    mapping(uint256 => Task) public tasks;

    // Mapping to track which users have completed which tasks.
    // task ID => user address => completion status
    mapping(uint256 => mapping(address => bool)) public completedTasks;

    /**
     * @dev Emitted when a new task is created.
     * @param taskId The unique ID of the task.
     * @param description The description of the task.
     * @param reward The reward for completing the task.
     */
    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);

    /**
     * @dev Emitted when a task is completed and the reward is claimed.
     * @param taskId The ID of the completed task.
     * @param user The address of the user who completed the task.
     * @param reward The reward amount claimed.
     */
    event TaskCompleted(uint256 indexed taskId, address indexed user, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "TaskRewardSystem: Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Creates a new task. The contract must be funded with enough ETH to cover the reward.
     * @param _description A description of the task.
     * @param _reward The ETH reward for completing the task.
     */
    function createTask(string memory _description, uint256 _reward) public onlyOwner {
        require(bytes(_description).length > 0, "Description cannot be empty.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(address(this).balance >= _reward, "Insufficient contract balance to fund the task reward.");

        _taskIds++;
        uint256 newTaskId = _taskIds;

        tasks[newTaskId] = Task({
            id: newTaskId,
            description: _description,
            reward: _reward,
            isActive: true
        });

        emit TaskCreated(newTaskId, _description, _reward);
    }

    /**
     * @dev Verifies that a user has completed a task. Can only be called by the owner.
     * @param _taskId The ID of the task.
     * @param _user The address of the user who completed the task.
     */
    function verifyTaskCompletion(uint256 _taskId, address _user) public onlyOwner {
        require(tasks[_taskId].isActive, "This task is not active.");
        require(!completedTasks[_taskId][_user], "This user has already been marked as completed for this task.");
        
        completedTasks[_taskId][_user] = true;
    }

    /**
     * @dev Allows a user to claim their reward for a completed task.
     * @param _taskId The ID of the task to claim the reward for.
     */
    function claimReward(uint256 _taskId) public {
        require(tasks[_taskId].isActive, "This task is not active.");
        require(completedTasks[_taskId][msg.sender], "You have not been verified for this task's completion.");

        uint256 reward = tasks[_taskId].reward;
        
        // Mark as claimed to prevent re-entry
        completedTasks[_taskId][msg.sender] = false; 

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Failed to send reward.");

        emit TaskCompleted(_taskId, msg.sender, reward);
    }
}
