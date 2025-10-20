// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TodoList
 * @dev A contract that allows users to create and manage to-do lists stored on-chain
 */
contract TodoList {
    // Task structure
    struct Task {
        uint256 id;
        string content;
        bool completed;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    // Mapping from user address to their tasks
    mapping(address => Task[]) public userTasks;
    
    // Mapping to track task count per user
    mapping(address => uint256) public userTaskCount;
    
    // Events
    event TaskCreated(address indexed user, uint256 indexed taskId, string content, uint256 timestamp);
    event TaskCompleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    event TaskUncompleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    event TaskUpdated(address indexed user, uint256 indexed taskId, string newContent);
    event TaskDeleted(address indexed user, uint256 indexed taskId);
    
    /**
     * @dev Create a new task
     * @param content The task content/description
     * @return taskId The ID of the created task
     */
    function createTask(string memory content) external returns (uint256) {
        require(bytes(content).length > 0, "Task content cannot be empty");
        require(bytes(content).length <= 500, "Task content too long");
        
        uint256 taskId = userTasks[msg.sender].length;
        
        Task memory newTask = Task({
            id: taskId,
            content: content,
            completed: false,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        userTasks[msg.sender].push(newTask);
        userTaskCount[msg.sender]++;
        
        emit TaskCreated(msg.sender, taskId, content, block.timestamp);
        
        return taskId;
    }
    
    /**
     * @dev Mark a task as completed
     * @param taskId The ID of the task to complete
     */
    function completeTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Invalid task ID");
        require(!userTasks[msg.sender][taskId].completed, "Task already completed");
        
        userTasks[msg.sender][taskId].completed = true;
        userTasks[msg.sender][taskId].completedAt = block.timestamp;
        
        emit TaskCompleted(msg.sender, taskId, block.timestamp);
    }
    
    /**
     * @dev Mark a task as not completed (undo completion)
     * @param taskId The ID of the task to uncomplete
     */
    function uncompleteTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Invalid task ID");
        require(userTasks[msg.sender][taskId].completed, "Task is not completed");
        
        userTasks[msg.sender][taskId].completed = false;
        userTasks[msg.sender][taskId].completedAt = 0;
        
        emit TaskUncompleted(msg.sender, taskId, block.timestamp);
    }
    
    /**
     * @dev Update task content
     * @param taskId The ID of the task to update
     * @param newContent The new task content
     */
    function updateTask(uint256 taskId, string memory newContent) external {
        require(taskId < userTasks[msg.sender].length, "Invalid task ID");
        require(bytes(newContent).length > 0, "Task content cannot be empty");
        require(bytes(newContent).length <= 500, "Task content too long");
        
        userTasks[msg.sender][taskId].content = newContent;
        
        emit TaskUpdated(msg.sender, taskId, newContent);
    }
    
    /**
     * @dev Delete a task (removes from array by swapping with last and popping)
     * @param taskId The ID of the task to delete
     */
    function deleteTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Invalid task ID");
        
        uint256 lastIndex = userTasks[msg.sender].length - 1;
        
        // If not the last element, swap with last element
        if (taskId != lastIndex) {
            userTasks[msg.sender][taskId] = userTasks[msg.sender][lastIndex];
            userTasks[msg.sender][taskId].id = taskId; // Update the ID
        }
        
        // Remove last element
        userTasks[msg.sender].pop();
        userTaskCount[msg.sender]--;
        
        emit TaskDeleted(msg.sender, taskId);
    }
    
    /**
     * @dev Get a specific task
     * @param user The user's address
     * @param taskId The ID of the task
     * @return id Task ID
     * @return content Task content
     * @return completed Whether task is completed
     * @return createdAt Creation timestamp
     * @return completedAt Completion timestamp
     */
    function getTask(address user, uint256 taskId) external view returns (
        uint256 id,
        string memory content,
        bool completed,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(taskId < userTasks[user].length, "Invalid task ID");
        
        Task memory task = userTasks[user][taskId];
        return (
            task.id,
            task.content,
            task.completed,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Get all tasks for a user
     * @param user The user's address
     * @return Array of all tasks
     */
    function getAllTasks(address user) external view returns (Task[] memory) {
        return userTasks[user];
    }
    
    /**
     * @dev Get all tasks for the caller
     * @return Array of all tasks
     */
    function getMyTasks() external view returns (Task[] memory) {
        return userTasks[msg.sender];
    }
    
    /**
     * @dev Get completed tasks for a user
     * @param user The user's address
     * @return Array of completed tasks
     */
    function getCompletedTasks(address user) external view returns (Task[] memory) {
        uint256 completedCount = 0;
        
        // Count completed tasks
        for (uint256 i = 0; i < userTasks[user].length; i++) {
            if (userTasks[user][i].completed) {
                completedCount++;
            }
        }
        
        // Create array
        Task[] memory completedTasks = new Task[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[user].length; i++) {
            if (userTasks[user][i].completed) {
                completedTasks[index] = userTasks[user][i];
                index++;
            }
        }
        
        return completedTasks;
    }
    
    /**
     * @dev Get pending (not completed) tasks for a user
     * @param user The user's address
     * @return Array of pending tasks
     */
    function getPendingTasks(address user) external view returns (Task[] memory) {
        uint256 pendingCount = 0;
        
        // Count pending tasks
        for (uint256 i = 0; i < userTasks[user].length; i++) {
            if (!userTasks[user][i].completed) {
                pendingCount++;
            }
        }
        
        // Create array
        Task[] memory pendingTasks = new Task[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[user].length; i++) {
            if (!userTasks[user][i].completed) {
                pendingTasks[index] = userTasks[user][i];
                index++;
            }
        }
        
        return pendingTasks;
    }
    
    /**
     * @dev Get the number of tasks for a user
     * @param user The user's address
     * @return The total number of tasks
     */
    function getTaskCount(address user) external view returns (uint256) {
        return userTasks[user].length;
    }
    
    /**
     * @dev Get task statistics for a user
     * @param user The user's address
     * @return total Total number of tasks
     * @return completed Number of completed tasks
     * @return pending Number of pending tasks
     */
    function getTaskStats(address user) external view returns (
        uint256 total,
        uint256 completed,
        uint256 pending
    ) {
        uint256 completedCount = 0;
        
        for (uint256 i = 0; i < userTasks[user].length; i++) {
            if (userTasks[user][i].completed) {
                completedCount++;
            }
        }
        
        return (
            userTasks[user].length,
            completedCount,
            userTasks[user].length - completedCount
        );
    }
    
    /**
     * @dev Get caller's task statistics
     * @return total Total number of tasks
     * @return completed Number of completed tasks
     * @return pending Number of pending tasks
     */
    function getMyTaskStats() external view returns (
        uint256 total,
        uint256 completed,
        uint256 pending
    ) {
        uint256 completedCount = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].completed) {
                completedCount++;
            }
        }
        
        return (
            userTasks[msg.sender].length,
            completedCount,
            userTasks[msg.sender].length - completedCount
        );
    }
    
    /**
     * @dev Clear all completed tasks for the caller
     * @return The number of tasks deleted
     */
    function clearCompletedTasks() external returns (uint256) {
        uint256 deletedCount = 0;
        
        // Iterate backwards to avoid index issues when deleting
        for (uint256 i = userTasks[msg.sender].length; i > 0; i--) {
            uint256 index = i - 1;
            if (userTasks[msg.sender][index].completed) {
                // Swap with last element
                uint256 lastIndex = userTasks[msg.sender].length - 1;
                if (index != lastIndex) {
                    userTasks[msg.sender][index] = userTasks[msg.sender][lastIndex];
                    userTasks[msg.sender][index].id = index;
                }
                userTasks[msg.sender].pop();
                userTaskCount[msg.sender]--;
                deletedCount++;
            }
        }
        
        return deletedCount;
    }
    
    /**
     * @dev Check if a task is completed
     * @param user The user's address
     * @param taskId The ID of the task
     * @return True if the task is completed, false otherwise
     */
    function isTaskCompleted(address user, uint256 taskId) external view returns (bool) {
        require(taskId < userTasks[user].length, "Invalid task ID");
        return userTasks[user][taskId].completed;
    }
}
