// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        uint256 taskId;
        string content;
        bool isCompleted;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    mapping(address => Task[]) public userTasks;
    mapping(address => uint256) public taskCount;
    
    event TaskCreated(address indexed user, uint256 taskId, string content, uint256 timestamp);
    event TaskCompleted(address indexed user, uint256 taskId, uint256 timestamp);
    event TaskUncompleted(address indexed user, uint256 taskId, uint256 timestamp);
    event TaskUpdated(address indexed user, uint256 taskId, string newContent);
    event TaskDeleted(address indexed user, uint256 taskId);
    
    function createTask(string memory _content) external {
        require(bytes(_content).length > 0, "Task content cannot be empty");
        require(bytes(_content).length <= 500, "Task content too long");
        
        uint256 taskId = userTasks[msg.sender].length;
        
        userTasks[msg.sender].push(Task({
            taskId: taskId,
            content: _content,
            isCompleted: false,
            createdAt: block.timestamp,
            completedAt: 0
        }));
        
        taskCount[msg.sender]++;
        
        emit TaskCreated(msg.sender, taskId, _content, block.timestamp);
    }
    
    function completeTask(uint256 _taskId) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        Task storage task = userTasks[msg.sender][_taskId];
        
        require(!task.isCompleted, "Task is already completed");
        
        task.isCompleted = true;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(msg.sender, _taskId, block.timestamp);
    }
    
    function uncompleteTask(uint256 _taskId) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        Task storage task = userTasks[msg.sender][_taskId];
        
        require(task.isCompleted, "Task is not completed");
        
        task.isCompleted = false;
        task.completedAt = 0;
        
        emit TaskUncompleted(msg.sender, _taskId, block.timestamp);
    }
    
    function updateTask(uint256 _taskId, string memory _newContent) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        require(bytes(_newContent).length > 0, "Task content cannot be empty");
        require(bytes(_newContent).length <= 500, "Task content too long");
        
        Task storage task = userTasks[msg.sender][_taskId];
        task.content = _newContent;
        
        emit TaskUpdated(msg.sender, _taskId, _newContent);
    }
    
    function deleteTask(uint256 _taskId) external {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        
        // Move the last task to the position of the task to delete
        uint256 lastIndex = userTasks[msg.sender].length - 1;
        
        if (_taskId != lastIndex) {
            userTasks[msg.sender][_taskId] = userTasks[msg.sender][lastIndex];
            userTasks[msg.sender][_taskId].taskId = _taskId;
        }
        
        userTasks[msg.sender].pop();
        taskCount[msg.sender]--;
        
        emit TaskDeleted(msg.sender, _taskId);
    }
    
    function getTask(uint256 _taskId) external view returns (
        uint256 taskId,
        string memory content,
        bool isCompleted,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(_taskId < userTasks[msg.sender].length, "Invalid task ID");
        Task memory task = userTasks[msg.sender][_taskId];
        
        return (
            task.taskId,
            task.content,
            task.isCompleted,
            task.createdAt,
            task.completedAt
        );
    }
    
    function getAllTasks() external view returns (Task[] memory) {
        return userTasks[msg.sender];
    }
    
    function getTaskCount() external view returns (uint256) {
        return userTasks[msg.sender].length;
    }
    
    function getCompletedTasks() external view returns (Task[] memory) {
        uint256 completedCount = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].isCompleted) {
                completedCount++;
            }
        }
        
        Task[] memory completedTasks = new Task[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].isCompleted) {
                completedTasks[index] = userTasks[msg.sender][i];
                index++;
            }
        }
        
        return completedTasks;
    }
    
    function getPendingTasks() external view returns (Task[] memory) {
        uint256 pendingCount = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (!userTasks[msg.sender][i].isCompleted) {
                pendingCount++;
            }
        }
        
        Task[] memory pendingTasks = new Task[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (!userTasks[msg.sender][i].isCompleted) {
                pendingTasks[index] = userTasks[msg.sender][i];
                index++;
            }
        }
        
        return pendingTasks;
    }
    
    function getTaskStats() external view returns (
        uint256 totalTasks,
        uint256 completedTasks,
        uint256 pendingTasks
    ) {
        uint256 total = userTasks[msg.sender].length;
        uint256 completed = 0;
        
        for (uint256 i = 0; i < total; i++) {
            if (userTasks[msg.sender][i].isCompleted) {
                completed++;
            }
        }
        
        return (total, completed, total - completed);
    }
}
