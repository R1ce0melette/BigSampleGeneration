// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ToDoList
 * @dev Contract that allows users to create and manage to-do lists stored on-chain
 */
contract ToDoList {
    // Task structure
    struct Task {
        uint256 id;
        address owner;
        string title;
        string description;
        bool completed;
        uint256 createdAt;
        uint256 completedAt;
        uint256 priority; // 1: Low, 2: Medium, 3: High
        string category;
    }

    // User statistics
    struct UserStats {
        uint256 totalTasks;
        uint256 completedTasks;
        uint256 pendingTasks;
    }

    // State variables
    uint256 private taskCounter;
    
    mapping(uint256 => Task) private tasks;
    mapping(address => uint256[]) private userTaskIds;
    mapping(address => UserStats) private userStats;
    
    uint256[] private allTaskIds;

    // Events
    event TaskCreated(uint256 indexed taskId, address indexed owner, string title, uint256 timestamp);
    event TaskCompleted(uint256 indexed taskId, address indexed owner, uint256 timestamp);
    event TaskUpdated(uint256 indexed taskId, address indexed owner);
    event TaskDeleted(uint256 indexed taskId, address indexed owner);
    event TaskReopened(uint256 indexed taskId, address indexed owner);

    // Modifiers
    modifier taskExists(uint256 taskId) {
        require(taskId > 0 && taskId <= taskCounter, "Task does not exist");
        _;
    }

    modifier onlyTaskOwner(uint256 taskId) {
        require(tasks[taskId].owner == msg.sender, "Not the task owner");
        _;
    }

    constructor() {
        taskCounter = 0;
    }

    /**
     * @dev Create a new task
     * @param title Task title
     * @param description Task description
     * @param priority Task priority (1: Low, 2: Medium, 3: High)
     * @param category Task category
     * @return taskId ID of the created task
     */
    function createTask(
        string memory title,
        string memory description,
        uint256 priority,
        string memory category
    ) public returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(priority >= 1 && priority <= 3, "Priority must be 1, 2, or 3");

        taskCounter++;
        uint256 taskId = taskCounter;

        Task storage newTask = tasks[taskId];
        newTask.id = taskId;
        newTask.owner = msg.sender;
        newTask.title = title;
        newTask.description = description;
        newTask.completed = false;
        newTask.createdAt = block.timestamp;
        newTask.priority = priority;
        newTask.category = category;

        userTaskIds[msg.sender].push(taskId);
        allTaskIds.push(taskId);

        userStats[msg.sender].totalTasks++;
        userStats[msg.sender].pendingTasks++;

        emit TaskCreated(taskId, msg.sender, title, block.timestamp);

        return taskId;
    }

    /**
     * @dev Create a simple task with just title
     * @param title Task title
     * @return taskId ID of the created task
     */
    function createSimpleTask(string memory title) public returns (uint256) {
        return createTask(title, "", 2, "");
    }

    /**
     * @dev Complete a task
     * @param taskId Task ID
     */
    function completeTask(uint256 taskId) 
        public 
        taskExists(taskId)
        onlyTaskOwner(taskId)
    {
        Task storage task = tasks[taskId];
        require(!task.completed, "Task is already completed");

        task.completed = true;
        task.completedAt = block.timestamp;

        userStats[msg.sender].completedTasks++;
        userStats[msg.sender].pendingTasks--;

        emit TaskCompleted(taskId, msg.sender, block.timestamp);
    }

    /**
     * @dev Reopen a completed task
     * @param taskId Task ID
     */
    function reopenTask(uint256 taskId) 
        public 
        taskExists(taskId)
        onlyTaskOwner(taskId)
    {
        Task storage task = tasks[taskId];
        require(task.completed, "Task is not completed");

        task.completed = false;
        task.completedAt = 0;

        userStats[msg.sender].completedTasks--;
        userStats[msg.sender].pendingTasks++;

        emit TaskReopened(taskId, msg.sender);
    }

    /**
     * @dev Update task details
     * @param taskId Task ID
     * @param title New title
     * @param description New description
     * @param priority New priority
     * @param category New category
     */
    function updateTask(
        uint256 taskId,
        string memory title,
        string memory description,
        uint256 priority,
        string memory category
    ) public taskExists(taskId) onlyTaskOwner(taskId) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(priority >= 1 && priority <= 3, "Priority must be 1, 2, or 3");

        Task storage task = tasks[taskId];
        task.title = title;
        task.description = description;
        task.priority = priority;
        task.category = category;

        emit TaskUpdated(taskId, msg.sender);
    }

    /**
     * @dev Delete a task
     * @param taskId Task ID
     */
    function deleteTask(uint256 taskId) 
        public 
        taskExists(taskId)
        onlyTaskOwner(taskId)
    {
        Task storage task = tasks[taskId];
        
        if (!task.completed) {
            userStats[msg.sender].pendingTasks--;
        } else {
            userStats[msg.sender].completedTasks--;
        }
        userStats[msg.sender].totalTasks--;

        emit TaskDeleted(taskId, msg.sender);

        delete tasks[taskId];
    }

    /**
     * @dev Get task details
     * @param taskId Task ID
     * @return Task details
     */
    function getTask(uint256 taskId) 
        public 
        view 
        taskExists(taskId)
        returns (Task memory) 
    {
        return tasks[taskId];
    }

    /**
     * @dev Get all tasks for a user
     * @param user User address
     * @return Array of tasks
     */
    function getUserTasks(address user) public view returns (Task[] memory) {
        uint256[] memory taskIds = userTaskIds[user];
        
        uint256 count = 0;
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (tasks[taskIds[i]].owner != address(0)) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < taskIds.length; i++) {
            if (tasks[taskIds[i]].owner != address(0)) {
                result[index] = tasks[taskIds[i]];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get caller's tasks
     * @return Array of tasks
     */
    function getMyTasks() public view returns (Task[] memory) {
        return getUserTasks(msg.sender);
    }

    /**
     * @dev Get pending tasks for a user
     * @param user User address
     * @return Array of pending tasks
     */
    function getUserPendingTasks(address user) public view returns (Task[] memory) {
        uint256[] memory taskIds = userTaskIds[user];
        
        uint256 count = 0;
        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && !task.completed) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && !task.completed) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get caller's pending tasks
     * @return Array of pending tasks
     */
    function getMyPendingTasks() public view returns (Task[] memory) {
        return getUserPendingTasks(msg.sender);
    }

    /**
     * @dev Get completed tasks for a user
     * @param user User address
     * @return Array of completed tasks
     */
    function getUserCompletedTasks(address user) public view returns (Task[] memory) {
        uint256[] memory taskIds = userTaskIds[user];
        
        uint256 count = 0;
        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && task.completed) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && task.completed) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get caller's completed tasks
     * @return Array of completed tasks
     */
    function getMyCompletedTasks() public view returns (Task[] memory) {
        return getUserCompletedTasks(msg.sender);
    }

    /**
     * @dev Get tasks by priority
     * @param user User address
     * @param priority Priority level (1: Low, 2: Medium, 3: High)
     * @return Array of tasks with the specified priority
     */
    function getUserTasksByPriority(address user, uint256 priority) 
        public 
        view 
        returns (Task[] memory) 
    {
        require(priority >= 1 && priority <= 3, "Priority must be 1, 2, or 3");
        
        uint256[] memory taskIds = userTaskIds[user];
        
        uint256 count = 0;
        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && task.priority == priority) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && task.priority == priority) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get caller's tasks by priority
     * @param priority Priority level (1: Low, 2: Medium, 3: High)
     * @return Array of tasks with the specified priority
     */
    function getMyTasksByPriority(uint256 priority) public view returns (Task[] memory) {
        return getUserTasksByPriority(msg.sender, priority);
    }

    /**
     * @dev Get tasks by category
     * @param user User address
     * @param category Task category
     * @return Array of tasks in the specified category
     */
    function getUserTasksByCategory(address user, string memory category) 
        public 
        view 
        returns (Task[] memory) 
    {
        uint256[] memory taskIds = userTaskIds[user];
        
        uint256 count = 0;
        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && 
                keccak256(bytes(task.category)) == keccak256(bytes(category))) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < taskIds.length; i++) {
            Task memory task = tasks[taskIds[i]];
            if (task.owner != address(0) && 
                keccak256(bytes(task.category)) == keccak256(bytes(category))) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get caller's tasks by category
     * @param category Task category
     * @return Array of tasks in the specified category
     */
    function getMyTasksByCategory(string memory category) public view returns (Task[] memory) {
        return getUserTasksByCategory(msg.sender, category);
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return UserStats structure
     */
    function getUserStats(address user) public view returns (UserStats memory) {
        return userStats[user];
    }

    /**
     * @dev Get caller's statistics
     * @return UserStats structure
     */
    function getMyStats() public view returns (UserStats memory) {
        return userStats[msg.sender];
    }

    /**
     * @dev Get user task IDs
     * @param user User address
     * @return Array of task IDs
     */
    function getUserTaskIds(address user) public view returns (uint256[] memory) {
        return userTaskIds[user];
    }

    /**
     * @dev Get caller's task IDs
     * @return Array of task IDs
     */
    function getMyTaskIds() public view returns (uint256[] memory) {
        return userTaskIds[msg.sender];
    }

    /**
     * @dev Get all tasks
     * @return Array of all tasks
     */
    function getAllTasks() public view returns (Task[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            if (tasks[allTaskIds[i]].owner != address(0)) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTaskIds.length; i++) {
            if (tasks[allTaskIds[i]].owner != address(0)) {
                result[index] = tasks[allTaskIds[i]];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total task count
     * @return Total number of tasks
     */
    function getTotalTaskCount() public view returns (uint256) {
        return taskCounter;
    }

    /**
     * @dev Get user task count
     * @param user User address
     * @return Total, pending, and completed counts
     */
    function getUserTaskCount(address user) 
        public 
        view 
        returns (uint256 total, uint256 pending, uint256 completed) 
    {
        UserStats memory stats = userStats[user];
        return (stats.totalTasks, stats.pendingTasks, stats.completedTasks);
    }

    /**
     * @dev Get caller's task count
     * @return Total, pending, and completed counts
     */
    function getMyTaskCount() 
        public 
        view 
        returns (uint256 total, uint256 pending, uint256 completed) 
    {
        return getUserTaskCount(msg.sender);
    }

    /**
     * @dev Get completion rate for user
     * @param user User address
     * @return Completion rate in percentage (scaled by 100)
     */
    function getUserCompletionRate(address user) public view returns (uint256) {
        UserStats memory stats = userStats[user];
        if (stats.totalTasks == 0) {
            return 0;
        }
        return (stats.completedTasks * 10000) / stats.totalTasks;
    }

    /**
     * @dev Get caller's completion rate
     * @return Completion rate in percentage (scaled by 100)
     */
    function getMyCompletionRate() public view returns (uint256) {
        return getUserCompletionRate(msg.sender);
    }

    /**
     * @dev Batch complete tasks
     * @param taskIds Array of task IDs to complete
     */
    function batchCompleteTasks(uint256[] memory taskIds) public {
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (taskIds[i] > 0 && taskIds[i] <= taskCounter) {
                Task storage task = tasks[taskIds[i]];
                if (task.owner == msg.sender && !task.completed) {
                    task.completed = true;
                    task.completedAt = block.timestamp;
                    userStats[msg.sender].completedTasks++;
                    userStats[msg.sender].pendingTasks--;
                    emit TaskCompleted(taskIds[i], msg.sender, block.timestamp);
                }
            }
        }
    }

    /**
     * @dev Batch delete tasks
     * @param taskIds Array of task IDs to delete
     */
    function batchDeleteTasks(uint256[] memory taskIds) public {
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (taskIds[i] > 0 && taskIds[i] <= taskCounter) {
                Task storage task = tasks[taskIds[i]];
                if (task.owner == msg.sender) {
                    if (!task.completed) {
                        userStats[msg.sender].pendingTasks--;
                    } else {
                        userStats[msg.sender].completedTasks--;
                    }
                    userStats[msg.sender].totalTasks--;
                    emit TaskDeleted(taskIds[i], msg.sender);
                    delete tasks[taskIds[i]];
                }
            }
        }
    }
}
