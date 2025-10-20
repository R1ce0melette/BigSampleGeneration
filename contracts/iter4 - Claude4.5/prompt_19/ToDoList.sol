// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TodoList
 * @dev A contract that allows users to create and manage to-do lists stored on-chain
 */
contract TodoList {
    struct Task {
        uint256 id;
        string content;
        bool completed;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    // Mapping from user address to their task count
    mapping(address => uint256) public userTaskCount;
    
    // Mapping from user address to task ID to task
    mapping(address => mapping(uint256 => Task)) public tasks;
    
    // Events
    event TaskCreated(address indexed user, uint256 indexed taskId, string content, uint256 timestamp);
    event TaskCompleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    event TaskUncompleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    event TaskUpdated(address indexed user, uint256 indexed taskId, string newContent, uint256 timestamp);
    event TaskDeleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    
    /**
     * @dev Creates a new task for the caller
     * @param _content The content/description of the task
     */
    function createTask(string memory _content) external {
        require(bytes(_content).length > 0, "Task content cannot be empty");
        require(bytes(_content).length <= 500, "Task content too long");
        
        userTaskCount[msg.sender]++;
        uint256 taskId = userTaskCount[msg.sender];
        
        tasks[msg.sender][taskId] = Task({
            id: taskId,
            content: _content,
            completed: false,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        emit TaskCreated(msg.sender, taskId, _content, block.timestamp);
    }
    
    /**
     * @dev Marks a task as completed
     * @param _taskId The ID of the task
     */
    function completeTask(uint256 _taskId) external {
        require(_taskId > 0 && _taskId <= userTaskCount[msg.sender], "Invalid task ID");
        
        Task storage task = tasks[msg.sender][_taskId];
        require(!task.completed, "Task already completed");
        
        task.completed = true;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(msg.sender, _taskId, block.timestamp);
    }
    
    /**
     * @dev Marks a task as not completed (uncomplete)
     * @param _taskId The ID of the task
     */
    function uncompleteTask(uint256 _taskId) external {
        require(_taskId > 0 && _taskId <= userTaskCount[msg.sender], "Invalid task ID");
        
        Task storage task = tasks[msg.sender][_taskId];
        require(task.completed, "Task is not completed");
        
        task.completed = false;
        task.completedAt = 0;
        
        emit TaskUncompleted(msg.sender, _taskId, block.timestamp);
    }
    
    /**
     * @dev Updates the content of a task
     * @param _taskId The ID of the task
     * @param _newContent The new content for the task
     */
    function updateTask(uint256 _taskId, string memory _newContent) external {
        require(_taskId > 0 && _taskId <= userTaskCount[msg.sender], "Invalid task ID");
        require(bytes(_newContent).length > 0, "Task content cannot be empty");
        require(bytes(_newContent).length <= 500, "Task content too long");
        
        Task storage task = tasks[msg.sender][_taskId];
        task.content = _newContent;
        
        emit TaskUpdated(msg.sender, _taskId, _newContent, block.timestamp);
    }
    
    /**
     * @dev Deletes a task (actually marks it as deleted by clearing content)
     * @param _taskId The ID of the task
     */
    function deleteTask(uint256 _taskId) external {
        require(_taskId > 0 && _taskId <= userTaskCount[msg.sender], "Invalid task ID");
        
        delete tasks[msg.sender][_taskId];
        
        emit TaskDeleted(msg.sender, _taskId, block.timestamp);
    }
    
    /**
     * @dev Returns the details of a specific task
     * @param _user The address of the user
     * @param _taskId The ID of the task
     * @return id The task ID
     * @return content The task content
     * @return completed Whether the task is completed
     * @return createdAt When the task was created
     * @return completedAt When the task was completed (0 if not completed)
     */
    function getTask(address _user, uint256 _taskId) external view returns (
        uint256 id,
        string memory content,
        bool completed,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(_taskId > 0 && _taskId <= userTaskCount[_user], "Invalid task ID");
        
        Task memory task = tasks[_user][_taskId];
        
        return (
            task.id,
            task.content,
            task.completed,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Returns the caller's task
     * @param _taskId The ID of the task
     * @return id The task ID
     * @return content The task content
     * @return completed Whether the task is completed
     * @return createdAt When the task was created
     * @return completedAt When the task was completed (0 if not completed)
     */
    function getMyTask(uint256 _taskId) external view returns (
        uint256 id,
        string memory content,
        bool completed,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(_taskId > 0 && _taskId <= userTaskCount[msg.sender], "Invalid task ID");
        
        Task memory task = tasks[msg.sender][_taskId];
        
        return (
            task.id,
            task.content,
            task.completed,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Returns all tasks for a user (excluding deleted tasks)
     * @param _user The address of the user
     * @return Array of tasks
     */
    function getAllTasks(address _user) external view returns (Task[] memory) {
        uint256 taskCount = userTaskCount[_user];
        uint256 activeCount = 0;
        
        // Count non-deleted tasks
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[_user][i].content).length > 0) {
                activeCount++;
            }
        }
        
        // Create array of active tasks
        Task[] memory allTasks = new Task[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[_user][i].content).length > 0) {
                allTasks[index] = tasks[_user][i];
                index++;
            }
        }
        
        return allTasks;
    }
    
    /**
     * @dev Returns all tasks for the caller (excluding deleted tasks)
     * @return Array of tasks
     */
    function getMyTasks() external view returns (Task[] memory) {
        uint256 taskCount = userTaskCount[msg.sender];
        uint256 activeCount = 0;
        
        // Count non-deleted tasks
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[msg.sender][i].content).length > 0) {
                activeCount++;
            }
        }
        
        // Create array of active tasks
        Task[] memory myTasks = new Task[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[msg.sender][i].content).length > 0) {
                myTasks[index] = tasks[msg.sender][i];
                index++;
            }
        }
        
        return myTasks;
    }
    
    /**
     * @dev Returns all pending (not completed) tasks for the caller
     * @return Array of pending tasks
     */
    function getMyPendingTasks() external view returns (Task[] memory) {
        uint256 taskCount = userTaskCount[msg.sender];
        uint256 pendingCount = 0;
        
        // Count pending tasks
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[msg.sender][i].content).length > 0 && !tasks[msg.sender][i].completed) {
                pendingCount++;
            }
        }
        
        // Create array of pending tasks
        Task[] memory pendingTasks = new Task[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[msg.sender][i].content).length > 0 && !tasks[msg.sender][i].completed) {
                pendingTasks[index] = tasks[msg.sender][i];
                index++;
            }
        }
        
        return pendingTasks;
    }
    
    /**
     * @dev Returns all completed tasks for the caller
     * @return Array of completed tasks
     */
    function getMyCompletedTasks() external view returns (Task[] memory) {
        uint256 taskCount = userTaskCount[msg.sender];
        uint256 completedCount = 0;
        
        // Count completed tasks
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[msg.sender][i].content).length > 0 && tasks[msg.sender][i].completed) {
                completedCount++;
            }
        }
        
        // Create array of completed tasks
        Task[] memory completedTasks = new Task[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[msg.sender][i].content).length > 0 && tasks[msg.sender][i].completed) {
                completedTasks[index] = tasks[msg.sender][i];
                index++;
            }
        }
        
        return completedTasks;
    }
    
    /**
     * @dev Returns the total task count for a user
     * @param _user The address of the user
     * @return The total task count
     */
    function getUserTaskCount(address _user) external view returns (uint256) {
        return userTaskCount[_user];
    }
    
    /**
     * @dev Returns the caller's total task count
     * @return The total task count
     */
    function getMyTaskCount() external view returns (uint256) {
        return userTaskCount[msg.sender];
    }
    
    /**
     * @dev Returns statistics for the caller's tasks
     * @return total Total tasks created (including deleted)
     * @return active Active tasks (not deleted)
     * @return completed Completed tasks
     * @return pending Pending tasks
     */
    function getMyTaskStats() external view returns (
        uint256 total,
        uint256 active,
        uint256 completed,
        uint256 pending
    ) {
        uint256 taskCount = userTaskCount[msg.sender];
        uint256 activeCount = 0;
        uint256 completedCount = 0;
        uint256 pendingCount = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (bytes(tasks[msg.sender][i].content).length > 0) {
                activeCount++;
                if (tasks[msg.sender][i].completed) {
                    completedCount++;
                } else {
                    pendingCount++;
                }
            }
        }
        
        return (taskCount, activeCount, completedCount, pendingCount);
    }
}
