// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ToDoList
 * @dev A contract that allows users to create and manage to-do lists stored on-chain
 */
contract ToDoList {
    struct Task {
        uint256 id;
        string description;
        bool completed;
        uint256 createdAt;
        uint256 completedAt;
        uint256 priority; // 1 = Low, 2 = Medium, 3 = High
    }
    
    mapping(address => Task[]) private userTasks;
    mapping(address => uint256) private taskCounters;
    
    event TaskCreated(address indexed user, uint256 taskId, string description, uint256 priority);
    event TaskCompleted(address indexed user, uint256 taskId);
    event TaskUncompleted(address indexed user, uint256 taskId);
    event TaskUpdated(address indexed user, uint256 taskId, string newDescription, uint256 newPriority);
    event TaskDeleted(address indexed user, uint256 taskId);
    
    /**
     * @dev Create a new task
     * @param description Task description
     * @param priority Task priority (1-3)
     * @return taskId The ID of the created task
     */
    function createTask(string memory description, uint256 priority) external returns (uint256) {
        require(bytes(description).length > 0, "Description cannot be empty");
        require(priority >= 1 && priority <= 3, "Priority must be 1, 2, or 3");
        
        uint256 taskId = userTasks[msg.sender].length;
        
        Task memory newTask = Task({
            id: taskId,
            description: description,
            completed: false,
            createdAt: block.timestamp,
            completedAt: 0,
            priority: priority
        });
        
        userTasks[msg.sender].push(newTask);
        taskCounters[msg.sender]++;
        
        emit TaskCreated(msg.sender, taskId, description, priority);
        
        return taskId;
    }
    
    /**
     * @dev Mark a task as completed
     * @param taskId The ID of the task
     */
    function completeTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        
        Task storage task = userTasks[msg.sender][taskId];
        require(!task.completed, "Task already completed");
        
        task.completed = true;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(msg.sender, taskId);
    }
    
    /**
     * @dev Mark a task as not completed
     * @param taskId The ID of the task
     */
    function uncompleteTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        
        Task storage task = userTasks[msg.sender][taskId];
        require(task.completed, "Task is not completed");
        
        task.completed = false;
        task.completedAt = 0;
        
        emit TaskUncompleted(msg.sender, taskId);
    }
    
    /**
     * @dev Update a task's description and priority
     * @param taskId The ID of the task
     * @param newDescription New description
     * @param newPriority New priority (1-3)
     */
    function updateTask(uint256 taskId, string memory newDescription, uint256 newPriority) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        require(bytes(newDescription).length > 0, "Description cannot be empty");
        require(newPriority >= 1 && newPriority <= 3, "Priority must be 1, 2, or 3");
        
        Task storage task = userTasks[msg.sender][taskId];
        task.description = newDescription;
        task.priority = newPriority;
        
        emit TaskUpdated(msg.sender, taskId, newDescription, newPriority);
    }
    
    /**
     * @dev Delete a task (marks it as empty)
     * @param taskId The ID of the task
     */
    function deleteTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        
        // Mark task as deleted by setting empty description
        Task storage task = userTasks[msg.sender][taskId];
        task.description = "";
        task.completed = false;
        
        emit TaskDeleted(msg.sender, taskId);
    }
    
    /**
     * @dev Get a specific task
     * @param taskId The ID of the task
     * @return id Task ID
     * @return description Task description
     * @return completed Whether task is completed
     * @return createdAt When the task was created
     * @return completedAt When the task was completed
     * @return priority Task priority
     */
    function getTask(uint256 taskId) external view returns (
        uint256 id,
        string memory description,
        bool completed,
        uint256 createdAt,
        uint256 completedAt,
        uint256 priority
    ) {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        
        Task memory task = userTasks[msg.sender][taskId];
        
        return (
            task.id,
            task.description,
            task.completed,
            task.createdAt,
            task.completedAt,
            task.priority
        );
    }
    
    /**
     * @dev Get all tasks for the caller
     * @return Array of all tasks
     */
    function getAllTasks() external view returns (Task[] memory) {
        return userTasks[msg.sender];
    }
    
    /**
     * @dev Get all tasks for a specific user
     * @param user The address of the user
     * @return Array of all tasks
     */
    function getUserTasks(address user) external view returns (Task[] memory) {
        return userTasks[user];
    }
    
    /**
     * @dev Get all active (not completed) tasks
     * @return Array of active tasks
     */
    function getActiveTasks() external view returns (Task[] memory) {
        uint256 count = 0;
        
        // Count active tasks
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (!userTasks[msg.sender][i].completed && bytes(userTasks[msg.sender][i].description).length > 0) {
                count++;
            }
        }
        
        // Create array and populate
        Task[] memory activeTasks = new Task[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (!userTasks[msg.sender][i].completed && bytes(userTasks[msg.sender][i].description).length > 0) {
                activeTasks[index] = userTasks[msg.sender][i];
                index++;
            }
        }
        
        return activeTasks;
    }
    
    /**
     * @dev Get all completed tasks
     * @return Array of completed tasks
     */
    function getCompletedTasks() external view returns (Task[] memory) {
        uint256 count = 0;
        
        // Count completed tasks
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].completed && bytes(userTasks[msg.sender][i].description).length > 0) {
                count++;
            }
        }
        
        // Create array and populate
        Task[] memory completedTasks = new Task[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].completed && bytes(userTasks[msg.sender][i].description).length > 0) {
                completedTasks[index] = userTasks[msg.sender][i];
                index++;
            }
        }
        
        return completedTasks;
    }
    
    /**
     * @dev Get tasks by priority
     * @param priority The priority level (1-3)
     * @return Array of tasks with the specified priority
     */
    function getTasksByPriority(uint256 priority) external view returns (Task[] memory) {
        require(priority >= 1 && priority <= 3, "Priority must be 1, 2, or 3");
        
        uint256 count = 0;
        
        // Count tasks with specified priority
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].priority == priority && bytes(userTasks[msg.sender][i].description).length > 0) {
                count++;
            }
        }
        
        // Create array and populate
        Task[] memory priorityTasks = new Task[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].priority == priority && bytes(userTasks[msg.sender][i].description).length > 0) {
                priorityTasks[index] = userTasks[msg.sender][i];
                index++;
            }
        }
        
        return priorityTasks;
    }
    
    /**
     * @dev Get task count for the caller
     * @return total Total tasks created
     * @return active Active tasks count
     * @return completed Completed tasks count
     */
    function getTaskStats() external view returns (
        uint256 total,
        uint256 active,
        uint256 completed
    ) {
        uint256 activeCount = 0;
        uint256 completedCount = 0;
        uint256 totalCount = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (bytes(userTasks[msg.sender][i].description).length > 0) {
                totalCount++;
                if (userTasks[msg.sender][i].completed) {
                    completedCount++;
                } else {
                    activeCount++;
                }
            }
        }
        
        return (totalCount, activeCount, completedCount);
    }
    
    /**
     * @dev Get total number of tasks (including deleted)
     * @return The total count
     */
    function getTotalTaskCount() external view returns (uint256) {
        return userTasks[msg.sender].length;
    }
    
    /**
     * @dev Check if a task is completed
     * @param taskId The ID of the task
     * @return Whether the task is completed
     */
    function isTaskCompleted(uint256 taskId) external view returns (bool) {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        return userTasks[msg.sender][taskId].completed;
    }
    
    /**
     * @dev Clear all completed tasks
     */
    function clearCompletedTasks() external {
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].completed) {
                userTasks[msg.sender][i].description = "";
                userTasks[msg.sender][i].completed = false;
                emit TaskDeleted(msg.sender, i);
            }
        }
    }
}
