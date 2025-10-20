// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ToDoList
 * @dev A contract for creating and managing personal to-do lists on-chain.
 */
contract ToDoList {

    struct Task {
        uint256 id;
        string content;
        bool isCompleted;
    }

    // Mapping from a user's address to their list of tasks.
    mapping(address => Task[]) public userTasks;
    // Mapping from a user's address to a counter for their next task ID.
    mapping(address => uint256) public nextTaskId;

    /**
     * @dev Event emitted when a new task is added.
     * @param user The address of the user.
     * @param taskId The ID of the new task.
     * @param content The content of the task.
     */
    event TaskAdded(address indexed user, uint256 indexed taskId, string content);

    /**
     * @dev Event emitted when a task is marked as completed.
     * @param user The address of the user.
     * @param taskId The ID of the completed task.
     */
    event TaskCompleted(address indexed user, uint256 indexed taskId);

    /**
     * @dev Adds a new task to the user's to-do list.
     * @param _content The content of the task.
     */
    function addTask(string memory _content) public {
        require(bytes(_content).length > 0, "Task content cannot be empty.");
        
        uint256 taskId = nextTaskId[msg.sender];
        userTasks[msg.sender].push(Task({
            id: taskId,
            content: _content,
            isCompleted: false
        }));
        
        nextTaskId[msg.sender]++;
        emit TaskAdded(msg.sender, taskId, _content);
    }

    /**
     * @dev Marks a task as completed.
     * @param _taskId The ID of the task to complete.
     */
    function completeTask(uint256 _taskId) public {
        require(_taskId < userTasks[msg.sender].length, "Task ID is out of bounds.");
        
        Task storage task = userTasks[msg.sender][_taskId];
        require(!task.isCompleted, "Task is already completed.");
        
        task.isCompleted = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    /**
     * @dev Retrieves a specific task from the user's list.
     * @param _taskId The ID of the task to retrieve.
     * @return The task's details.
     */
    function getTask(uint256 _taskId) public view returns (uint256, string memory, bool) {
        require(_taskId < userTasks[msg.sender].length, "Task ID is out of bounds.");
        Task storage task = userTasks[msg.sender][_taskId];
        return (task.id, task.content, task.isCompleted);
    }

    /**
     * @dev Returns the number of tasks for the calling user.
     * @return The total number of tasks.
     */
    function getTaskCount() public view returns (uint256) {
        return userTasks[msg.sender].length;
    }
}
