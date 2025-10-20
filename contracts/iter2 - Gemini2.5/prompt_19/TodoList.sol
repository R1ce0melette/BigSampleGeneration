// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        string content;
        bool isCompleted;
    }

    // Each user has their own list of tasks
    mapping(address => Task[]) public userTasks;
    // Keep track of the number of tasks per user
    mapping(address => uint256) public taskCount;

    event TaskAdded(address indexed user, uint256 taskId, string content);
    event TaskCompleted(address indexed user, uint256 taskId);
    event TaskUpdated(address indexed user, uint256 taskId, string newContent);

    /**
     * @dev Adds a new task to the sender's to-do list.
     * @param _content The content of the task.
     */
    function addTask(string memory _content) public {
        require(bytes(_content).length > 0, "Task content cannot be empty.");
        
        uint256 newTaskId = userTasks[msg.sender].length;
        userTasks[msg.sender].push(Task(_content, false));
        taskCount[msg.sender]++;

        emit TaskAdded(msg.sender, newTaskId, _content);
    }

    /**
     * @dev Marks a task as completed.
     * @param _taskId The ID (index) of the task to complete.
     */
    function completeTask(uint256 _taskId) public {
        require(_taskId < userTasks[msg.sender].length, "Task does not exist.");
        Task storage task = userTasks[msg.sender][_taskId];
        require(!task.isCompleted, "Task is already completed.");

        task.isCompleted = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    /**
     * @dev Updates the content of an existing task.
     * @param _taskId The ID (index) of the task to update.
     * @param _newContent The new content for the task.
     */
    function updateTask(uint256 _taskId, string memory _newContent) public {
        require(_taskId < userTasks[msg.sender].length, "Task does not exist.");
        require(bytes(_newContent).length > 0, "New content cannot be empty.");
        
        Task storage task = userTasks[msg.sender][_taskId];
        task.content = _newContent;

        emit TaskUpdated(msg.sender, _taskId, _newContent);
    }

    /**
     * @dev Retrieves a specific task for the sender.
     * @param _taskId The ID (index) of the task.
     * @return The content and completion status of the task.
     */
    function getTask(uint256 _taskId) public view returns (string memory, bool) {
        require(_taskId < userTasks[msg.sender].length, "Task does not exist.");
        Task storage task = userTasks[msg.sender][_taskId];
        return (task.content, task.isCompleted);
    }

    /**
     * @dev Gets the total number of tasks for the sender.
     * @return The number of tasks.
     */
    function getTaskCount() public view returns (uint256) {
        return taskCount[msg.sender];
    }
}
