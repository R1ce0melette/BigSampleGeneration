// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TodoList
 * @dev A contract that allows users to create and manage their personal to-do lists on-chain.
 */
contract TodoList {
    struct Task {
        uint256 id;
        string content;
        bool isCompleted;
    }

    // Mapping from a user's address to their list of tasks
    mapping(address => Task[]) public userTasks;
    // Mapping to keep track of the next task ID for each user
    mapping(address => uint256) public nextTaskId;

    /**
     * @dev Emitted when a new task is added to a user's to-do list.
     * @param user The address of the user.
     * @param taskId The ID of the new task.
     * @param content The content of the task.
     */
    event TaskAdded(address indexed user, uint256 taskId, string content);

    /**
     * @dev Emitted when a task is marked as completed.
     * @param user The address of the user.
     * @param taskId The ID of the completed task.
     */
    event TaskCompleted(address indexed user, uint256 taskId);

    /**
     * @dev Adds a new task to the sender's to-do list.
     * @param _content The content of the task.
     */
    function addTask(string memory _content) public {
        require(bytes(_content).length > 0, "Task content cannot be empty.");

        uint256 taskId = nextTaskId[msg.sender];
        userTasks[msg.sender].push(Task(taskId, _content, false));
        nextTaskId[msg.sender]++;

        emit TaskAdded(msg.sender, taskId, _content);
    }

    /**
     * @dev Marks a task as completed.
     * The task must exist and belong to the sender.
     * @param _taskId The ID of the task to complete.
     */
    function completeTask(uint256 _taskId) public {
        require(_taskId < userTasks[msg.sender].length, "Task ID is invalid.");
        
        Task storage task = userTasks[msg.sender][_taskId];
        require(!task.isCompleted, "Task is already completed.");

        task.isCompleted = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    /**
     * @dev Retrieves a specific task from the sender's to-do list.
     * @param _taskId The ID of the task to retrieve.
     * @return A tuple containing the task's ID, content, and completion status.
     */
    function getTask(uint256 _taskId) public view returns (uint256, string memory, bool) {
        require(_taskId < userTasks[msg.sender].length, "Task ID is invalid.");
        Task storage task = userTasks[msg.sender][_taskId];
        return (task.id, task.content, task.isCompleted);
    }

    /**
     * @dev Returns the total number of tasks in the sender's to-do list.
     * @return The count of tasks for the calling user.
     */
    function getTaskCount() public view returns (uint256) {
        return userTasks[msg.sender].length;
    }

    /**
     * @dev Retrieves all tasks for the calling user.
     * This can be gas-intensive for users with many tasks.
     * @return An array of all tasks for the user.
     */
    function getAllTasks() public view returns (Task[] memory) {
        return userTasks[msg.sender];
    }
}
