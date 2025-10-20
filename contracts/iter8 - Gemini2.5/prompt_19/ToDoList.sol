// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TodoList
 * @dev A contract that allows users to create and manage personal to-do lists on-chain.
 */
contract TodoList {
    struct Task {
        string content;
        bool isCompleted;
    }

    // Mapping from a user's address to their list of tasks
    mapping(address => Task[]) public userTasks;

    event TaskAdded(address indexed user, uint256 taskId, string content);
    event TaskCompleted(address indexed user, uint256 taskId);
    event TaskUpdated(address indexed user, uint256 taskId, string newContent);

    /**
     * @dev Adds a new task to the sender's to-do list.
     * @param _content The content of the task.
     */
    function addTask(string memory _content) external {
        require(bytes(_content).length > 0, "Task content cannot be empty.");
        
        userTasks[msg.sender].push(Task({
            content: _content,
            isCompleted: false
        }));
        
        uint256 taskId = userTasks[msg.sender].length - 1;
        emit TaskAdded(msg.sender, taskId, _content);
    }

    /**
     * @dev Marks a task as completed.
     * @param _taskId The index of the task in the user's list.
     */
    function completeTask(uint256 _taskId) external {
        require(_taskId < userTasks[msg.sender].length, "Task does not exist.");
        require(!userTasks[msg.sender][_taskId].isCompleted, "Task is already completed.");
        
        userTasks[msg.sender][_taskId].isCompleted = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    /**
     * @dev Updates the content of an existing task.
     * @param _taskId The index of the task to update.
     * @param _newContent The new content for the task.
     */
    function updateTask(uint256 _taskId, string memory _newContent) external {
        require(_taskId < userTasks[msg.sender].length, "Task does not exist.");
        require(bytes(_newContent).length > 0, "Task content cannot be empty.");

        userTasks[msg.sender][_taskId].content = _newContent;
        emit TaskUpdated(msg.sender, _taskId, _newContent);
    }

    /**
     * @dev Retrieves a specific task for the sender.
     * @param _taskId The index of the task.
     * @return The task's content and completion status.
     */
    function getTask(uint256 _taskId) external view returns (string memory, bool) {
        require(_taskId < userTasks[msg.sender].length, "Task does not exist.");
        Task storage task = userTasks[msg.sender][_taskId];
        return (task.content, task.isCompleted);
    }

    /**
     * @dev Returns the total number of tasks for the sender.
     * @return The count of tasks.
     */
    function getTaskCount() external view returns (uint256) {
        return userTasks[msg.sender].length;
    }
}
