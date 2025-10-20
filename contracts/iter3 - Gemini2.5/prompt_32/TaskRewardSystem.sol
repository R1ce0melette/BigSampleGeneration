// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TaskRewardSystem
 * @dev A contract for a simple task reward system. An owner can create tasks
 * with ETH rewards, and users can claim rewards upon task completion.
 */
contract TaskRewardSystem {
    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        bool isActive;
        mapping(address => bool) isCompletedBy;
    }

    address public owner;
    uint256 private _taskIdCounter;
    mapping(uint256 => Task) public tasks;

    /**
     * @dev Emitted when a new task is created.
     * @param taskId The unique ID of the task.
     * @param description A description of the task.
     * @param reward The reward for completing the task.
     */
    event TaskCreated(uint256 indexed taskId, string description, uint256 reward);

    /**
     * @dev Emitted when a task is completed by a user.
     * @param taskId The ID of the completed task.
     * @param user The address of the user who completed the task.
     */
    event TaskCompleted(uint256 indexed taskId, address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Creates a new task with a specified reward.
     * The owner must send enough ETH to the contract to fund the reward.
     * @param _description A description of the task.
     */
    function createTask(string memory _description) public payable onlyOwner {
        require(bytes(_description).length > 0, "Task description cannot be empty.");
        require(msg.value > 0, "Task reward must be greater than zero.");

        _taskIdCounter++;
        uint256 newTaskId = _taskIdCounter;
        
        Task storage newTask = tasks[newTaskId];
        newTask.id = newTaskId;
        newTask.description = _description;
        newTask.reward = msg.value;
        newTask.isActive = true;

        emit TaskCreated(newTaskId, _description, msg.value);
    }

    /**
     * @dev Allows a user to claim the reward for completing a task.
     * This function assumes off-chain verification of task completion.
     * The owner calls this function to grant the reward to the user.
     * @param _taskId The ID of the task.
     * @param _user The address of the user who completed the task.
     */
    function completeTask(uint256 _taskId, address payable _user) public onlyOwner {
        require(_taskId > 0 && _taskId <= _taskIdCounter, "Invalid task ID.");
        
        Task storage task = tasks[_taskId];
        require(task.isActive, "This task is not active.");
        require(!task.isCompletedBy[_user], "This user has already completed this task.");
        require(address(this).balance >= task.reward, "Contract has insufficient funds to pay the reward.");

        task.isCompletedBy[_user] = true;
        _user.transfer(task.reward);

        emit TaskCompleted(_taskId, _user);
    }

    /**
     * @dev Allows the owner to deactivate a task.
     * @param _taskId The ID of the task to deactivate.
     */
    function deactivateTask(uint256 _taskId) public onlyOwner {
        require(_taskId > 0 && _taskId <= _taskIdCounter, "Invalid task ID.");
        tasks[_taskId].isActive = false;
    }

    /**
     * @dev Allows the owner to withdraw any excess funds from the contract.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(owner).transfer(balance);
    }

    /**
     * @dev Returns the details of a specific task.
     */
    function getTask(uint256 _taskId) public view returns (uint256, string memory, uint256, bool) {
        require(_taskId > 0 && _taskId <= _taskIdCounter, "Invalid task ID.");
        Task storage task = tasks[_taskId];
        return (task.id, task.description, task.reward, task.isActive);
    }
}
