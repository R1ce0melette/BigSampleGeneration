// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        uint256 id;
        string description;
        bool isCompleted;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    mapping(address => Task[]) public userTasks;
    mapping(address => uint256) public taskCount;
    
    // Events
    event TaskCreated(address indexed user, uint256 indexed taskId, string description);
    event TaskCompleted(address indexed user, uint256 indexed taskId);
    event TaskUncompleted(address indexed user, uint256 indexed taskId);
    event TaskUpdated(address indexed user, uint256 indexed taskId, string newDescription);
    event TaskDeleted(address indexed user, uint256 indexed taskId);
    
    /**
     * @dev Create a new task
     * @param _description The task description
     */
    function createTask(string memory _description) external {
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        uint256 taskId = userTasks[msg.sender].length;
        
        userTasks[msg.sender].push(Task({
            id: taskId,
            description: _description,
            isCompleted: false,
            createdAt: block.timestamp,
            completedAt: 0
        }));
        
        taskCount[msg.sender]++;
        
        emit TaskCreated(msg.sender, taskId, _description);
    }
    
    /**
     * @dev Mark a task as completed
     * @param _taskId The ID of the task
     */
    function completeTask(uint256 _taskId) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        
        Task storage task = userTasks[msg.sender][_taskId];
        
        require(!task.isCompleted, "Task already completed");
        
        task.isCompleted = true;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(msg.sender, _taskId);
    }
    
    /**
     * @dev Mark a task as uncompleted
     * @param _taskId The ID of the task
     */
    function uncompleteTask(uint256 _taskId) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        
        Task storage task = userTasks[msg.sender][_taskId];
        
        require(task.isCompleted, "Task is not completed");
        
        task.isCompleted = false;
        task.completedAt = 0;
        
        emit TaskUncompleted(msg.sender, _taskId);
    }
    
    /**
     * @dev Update task description
     * @param _taskId The ID of the task
     * @param _newDescription The new description
     */
    function updateTask(uint256 _taskId, string memory _newDescription) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        require(bytes(_newDescription).length > 0, "Description cannot be empty");
        
        Task storage task = userTasks[msg.sender][_taskId];
        
        task.description = _newDescription;
        
        emit TaskUpdated(msg.sender, _taskId, _newDescription);
    }
    
    /**
     * @dev Delete a task (marks it as empty but maintains array structure)
     * @param _taskId The ID of the task
     */
    function deleteTask(uint256 _taskId) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        
        Task storage task = userTasks[msg.sender][_taskId];
        
        task.description = "";
        task.isCompleted = false;
        task.completedAt = 0;
        
        taskCount[msg.sender]--;
        
        emit TaskDeleted(msg.sender, _taskId);
    }
    
    /**
     * @dev Get a specific task
     * @param _user The user address
     * @param _taskId The ID of the task
     * @return id The task ID
     * @return description The task description
     * @return isCompleted Whether the task is completed
     * @return createdAt The creation timestamp
     * @return completedAt The completion timestamp
     */
    function getTask(address _user, uint256 _taskId) external view returns (
        uint256 id,
        string memory description,
        bool isCompleted,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(_taskId < userTasks[_user].length, "Invalid task ID");
        
        Task memory task = userTasks[_user][_taskId];
        
        return (
            task.id,
            task.description,
            task.isCompleted,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Get all tasks for a user
     * @param _user The user address
     * @return Array of tasks
     */
    function getAllTasks(address _user) external view returns (Task[] memory) {
        return userTasks[_user];
    }
    
    /**
     * @dev Get all tasks for the caller
     * @return Array of tasks
     */
    function getMyTasks() external view returns (Task[] memory) {
        return userTasks[msg.sender];
    }
    
    /**
     * @dev Get pending (uncompleted) tasks for a user
     * @param _user The user address
     * @return Array of task IDs
     */
    function getPendingTasks(address _user) external view returns (uint256[] memory) {
        uint256 pendingCount = 0;
        
        // Count pending tasks
        for (uint256 i = 0; i < userTasks[_user].length; i++) {
            if (!userTasks[_user][i].isCompleted && bytes(userTasks[_user][i].description).length > 0) {
                pendingCount++;
            }
        }
        
        uint256[] memory pendingTaskIds = new uint256[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[_user].length; i++) {
            if (!userTasks[_user][i].isCompleted && bytes(userTasks[_user][i].description).length > 0) {
                pendingTaskIds[index] = i;
                index++;
            }
        }
        
        return pendingTaskIds;
    }
    
    /**
     * @dev Get completed tasks for a user
     * @param _user The user address
     * @return Array of task IDs
     */
    function getCompletedTasks(address _user) external view returns (uint256[] memory) {
        uint256 completedCount = 0;
        
        // Count completed tasks
        for (uint256 i = 0; i < userTasks[_user].length; i++) {
            if (userTasks[_user][i].isCompleted && bytes(userTasks[_user][i].description).length > 0) {
                completedCount++;
            }
        }
        
        uint256[] memory completedTaskIds = new uint256[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[_user].length; i++) {
            if (userTasks[_user][i].isCompleted && bytes(userTasks[_user][i].description).length > 0) {
                completedTaskIds[index] = i;
                index++;
            }
        }
        
        return completedTaskIds;
    }
    
    /**
     * @dev Get task statistics for a user
     * @param _user The user address
     * @return total Total number of tasks (including deleted)
     * @return active Active tasks (non-deleted)
     * @return completed Number of completed tasks
     * @return pending Number of pending tasks
     */
    function getTaskStats(address _user) external view returns (
        uint256 total,
        uint256 active,
        uint256 completed,
        uint256 pending
    ) {
        total = userTasks[_user].length;
        active = taskCount[_user];
        
        for (uint256 i = 0; i < userTasks[_user].length; i++) {
            if (bytes(userTasks[_user][i].description).length > 0) {
                if (userTasks[_user][i].isCompleted) {
                    completed++;
                } else {
                    pending++;
                }
            }
        }
        
        return (total, active, completed, pending);
    }
    
    /**
     * @dev Get the total number of tasks for a user
     * @param _user The user address
     * @return The total number of tasks
     */
    function getTotalTaskCount(address _user) external view returns (uint256) {
        return userTasks[_user].length;
    }
}
