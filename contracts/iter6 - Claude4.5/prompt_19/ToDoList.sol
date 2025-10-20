// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TodoList
 * @dev A contract that allows users to create and manage to-do lists stored on-chain
 */
contract TodoList {
    struct Task {
        uint256 id;
        string description;
        bool completed;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    // Mapping from user address to their task count
    mapping(address => uint256) public userTaskCount;
    
    // Mapping from user address to task ID to task
    mapping(address => mapping(uint256 => Task)) public userTasks;
    
    // Events
    event TaskCreated(address indexed user, uint256 indexed taskId, string description, uint256 timestamp);
    event TaskCompleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    event TaskUncompleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    event TaskUpdated(address indexed user, uint256 indexed taskId, string newDescription, uint256 timestamp);
    event TaskDeleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    
    /**
     * @dev Create a new task
     * @param description The task description
     */
    function createTask(string memory description) external {
        require(bytes(description).length > 0, "Task description cannot be empty");
        
        userTaskCount[msg.sender]++;
        uint256 taskId = userTaskCount[msg.sender];
        
        userTasks[msg.sender][taskId] = Task({
            id: taskId,
            description: description,
            completed: false,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        emit TaskCreated(msg.sender, taskId, description, block.timestamp);
    }
    
    /**
     * @dev Mark a task as completed
     * @param taskId The ID of the task to complete
     */
    function completeTask(uint256 taskId) external {
        require(taskId > 0 && taskId <= userTaskCount[msg.sender], "Invalid task ID");
        Task storage task = userTasks[msg.sender][taskId];
        
        require(!task.completed, "Task is already completed");
        require(bytes(task.description).length > 0, "Task does not exist");
        
        task.completed = true;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(msg.sender, taskId, block.timestamp);
    }
    
    /**
     * @dev Mark a task as uncompleted
     * @param taskId The ID of the task to uncomplete
     */
    function uncompleteTask(uint256 taskId) external {
        require(taskId > 0 && taskId <= userTaskCount[msg.sender], "Invalid task ID");
        Task storage task = userTasks[msg.sender][taskId];
        
        require(task.completed, "Task is not completed");
        require(bytes(task.description).length > 0, "Task does not exist");
        
        task.completed = false;
        task.completedAt = 0;
        
        emit TaskUncompleted(msg.sender, taskId, block.timestamp);
    }
    
    /**
     * @dev Update a task's description
     * @param taskId The ID of the task to update
     * @param newDescription The new task description
     */
    function updateTask(uint256 taskId, string memory newDescription) external {
        require(taskId > 0 && taskId <= userTaskCount[msg.sender], "Invalid task ID");
        require(bytes(newDescription).length > 0, "Task description cannot be empty");
        
        Task storage task = userTasks[msg.sender][taskId];
        require(bytes(task.description).length > 0, "Task does not exist");
        
        task.description = newDescription;
        
        emit TaskUpdated(msg.sender, taskId, newDescription, block.timestamp);
    }
    
    /**
     * @dev Delete a task
     * @param taskId The ID of the task to delete
     */
    function deleteTask(uint256 taskId) external {
        require(taskId > 0 && taskId <= userTaskCount[msg.sender], "Invalid task ID");
        
        Task storage task = userTasks[msg.sender][taskId];
        require(bytes(task.description).length > 0, "Task does not exist");
        
        delete userTasks[msg.sender][taskId];
        
        emit TaskDeleted(msg.sender, taskId, block.timestamp);
    }
    
    /**
     * @dev Get a task by ID
     * @param user The user's address
     * @param taskId The task ID
     * @return id Task ID
     * @return description Task description
     * @return completed Whether the task is completed
     * @return createdAt Creation timestamp
     * @return completedAt Completion timestamp
     */
    function getTask(address user, uint256 taskId) external view returns (
        uint256 id,
        string memory description,
        bool completed,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(taskId > 0 && taskId <= userTaskCount[user], "Invalid task ID");
        Task memory task = userTasks[user][taskId];
        
        return (
            task.id,
            task.description,
            task.completed,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Get the caller's task by ID
     * @param taskId The task ID
     * @return id Task ID
     * @return description Task description
     * @return completed Whether the task is completed
     * @return createdAt Creation timestamp
     * @return completedAt Completion timestamp
     */
    function getMyTask(uint256 taskId) external view returns (
        uint256 id,
        string memory description,
        bool completed,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(taskId > 0 && taskId <= userTaskCount[msg.sender], "Invalid task ID");
        Task memory task = userTasks[msg.sender][taskId];
        
        return (
            task.id,
            task.description,
            task.completed,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Get all task IDs for a user
     * @param user The user's address
     * @return Array of task IDs (includes deleted tasks as 0)
     */
    function getAllTaskIds(address user) external view returns (uint256[] memory) {
        uint256 count = userTaskCount[user];
        uint256[] memory taskIds = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            taskIds[i] = i + 1;
        }
        
        return taskIds;
    }
    
    /**
     * @dev Get all active (non-deleted) task IDs for a user
     * @param user The user's address
     * @return Array of active task IDs
     */
    function getActiveTaskIds(address user) external view returns (uint256[] memory) {
        uint256 count = userTaskCount[user];
        uint256 activeCount = 0;
        
        // Count active tasks
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[user][i].description).length > 0) {
                activeCount++;
            }
        }
        
        // Collect active task IDs
        uint256[] memory taskIds = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[user][i].description).length > 0) {
                taskIds[index] = i;
                index++;
            }
        }
        
        return taskIds;
    }
    
    /**
     * @dev Get all completed task IDs for a user
     * @param user The user's address
     * @return Array of completed task IDs
     */
    function getCompletedTaskIds(address user) external view returns (uint256[] memory) {
        uint256 count = userTaskCount[user];
        uint256 completedCount = 0;
        
        // Count completed tasks
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[user][i].description).length > 0 && userTasks[user][i].completed) {
                completedCount++;
            }
        }
        
        // Collect completed task IDs
        uint256[] memory taskIds = new uint256[](completedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[user][i].description).length > 0 && userTasks[user][i].completed) {
                taskIds[index] = i;
                index++;
            }
        }
        
        return taskIds;
    }
    
    /**
     * @dev Get all pending (not completed) task IDs for a user
     * @param user The user's address
     * @return Array of pending task IDs
     */
    function getPendingTaskIds(address user) external view returns (uint256[] memory) {
        uint256 count = userTaskCount[user];
        uint256 pendingCount = 0;
        
        // Count pending tasks
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[user][i].description).length > 0 && !userTasks[user][i].completed) {
                pendingCount++;
            }
        }
        
        // Collect pending task IDs
        uint256[] memory taskIds = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[user][i].description).length > 0 && !userTasks[user][i].completed) {
                taskIds[index] = i;
                index++;
            }
        }
        
        return taskIds;
    }
    
    /**
     * @dev Get the caller's statistics
     * @return totalTasks Total number of tasks created
     * @return activeTasks Number of active (non-deleted) tasks
     * @return completedTasks Number of completed tasks
     * @return pendingTasks Number of pending tasks
     */
    function getMyStats() external view returns (
        uint256 totalTasks,
        uint256 activeTasks,
        uint256 completedTasks,
        uint256 pendingTasks
    ) {
        uint256 count = userTaskCount[msg.sender];
        uint256 active = 0;
        uint256 completed = 0;
        uint256 pending = 0;
        
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[msg.sender][i].description).length > 0) {
                active++;
                if (userTasks[msg.sender][i].completed) {
                    completed++;
                } else {
                    pending++;
                }
            }
        }
        
        return (count, active, completed, pending);
    }
    
    /**
     * @dev Get statistics for a user
     * @param user The user's address
     * @return totalTasks Total number of tasks created
     * @return activeTasks Number of active (non-deleted) tasks
     * @return completedTasks Number of completed tasks
     * @return pendingTasks Number of pending tasks
     */
    function getUserStats(address user) external view returns (
        uint256 totalTasks,
        uint256 activeTasks,
        uint256 completedTasks,
        uint256 pendingTasks
    ) {
        uint256 count = userTaskCount[user];
        uint256 active = 0;
        uint256 completed = 0;
        uint256 pending = 0;
        
        for (uint256 i = 1; i <= count; i++) {
            if (bytes(userTasks[user][i].description).length > 0) {
                active++;
                if (userTasks[user][i].completed) {
                    completed++;
                } else {
                    pending++;
                }
            }
        }
        
        return (count, active, completed, pending);
    }
    
    /**
     * @dev Check if a task exists
     * @param user The user's address
     * @param taskId The task ID
     * @return True if the task exists, false otherwise
     */
    function taskExists(address user, uint256 taskId) external view returns (bool) {
        if (taskId == 0 || taskId > userTaskCount[user]) {
            return false;
        }
        return bytes(userTasks[user][taskId].description).length > 0;
    }
}
