// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        uint256 id;
        string description;
        bool completed;
        uint256 createdAt;
        uint256 completedAt;
    }

    mapping(address => Task[]) public userTasks;
    mapping(address => uint256) public taskCount;

    event TaskCreated(address indexed user, uint256 indexed taskId, string description, uint256 timestamp);
    event TaskCompleted(address indexed user, uint256 indexed taskId, uint256 timestamp);
    event TaskDeleted(address indexed user, uint256 indexed taskId);
    event TaskUpdated(address indexed user, uint256 indexed taskId, string newDescription);

    function createTask(string memory description) external {
        require(bytes(description).length > 0, "Task description cannot be empty");
        require(bytes(description).length <= 500, "Task description too long");

        uint256 taskId = userTasks[msg.sender].length;

        userTasks[msg.sender].push(Task({
            id: taskId,
            description: description,
            completed: false,
            createdAt: block.timestamp,
            completedAt: 0
        }));

        taskCount[msg.sender]++;

        emit TaskCreated(msg.sender, taskId, description, block.timestamp);
    }

    function completeTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        Task storage task = userTasks[msg.sender][taskId];
        require(!task.completed, "Task is already completed");

        task.completed = true;
        task.completedAt = block.timestamp;

        emit TaskCompleted(msg.sender, taskId, block.timestamp);
    }

    function uncompleteTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        Task storage task = userTasks[msg.sender][taskId];
        require(task.completed, "Task is not completed");

        task.completed = false;
        task.completedAt = 0;
    }

    function updateTask(uint256 taskId, string memory newDescription) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        require(bytes(newDescription).length > 0, "Task description cannot be empty");
        require(bytes(newDescription).length <= 500, "Task description too long");

        userTasks[msg.sender][taskId].description = newDescription;

        emit TaskUpdated(msg.sender, taskId, newDescription);
    }

    function deleteTask(uint256 taskId) external {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");

        Task[] storage tasks = userTasks[msg.sender];
        
        // Move the last task to the deleted position and pop
        if (taskId != tasks.length - 1) {
            tasks[taskId] = tasks[tasks.length - 1];
            tasks[taskId].id = taskId;
        }
        tasks.pop();
        taskCount[msg.sender]--;

        emit TaskDeleted(msg.sender, taskId);
    }

    function getTask(uint256 taskId) external view returns (
        uint256 id,
        string memory description,
        bool completed,
        uint256 createdAt,
        uint256 completedAt
    ) {
        require(taskId < userTasks[msg.sender].length, "Task does not exist");
        Task memory task = userTasks[msg.sender][taskId];
        return (task.id, task.description, task.completed, task.createdAt, task.completedAt);
    }

    function getAllTasks() external view returns (Task[] memory) {
        return userTasks[msg.sender];
    }

    function getCompletedTasks() external view returns (Task[] memory) {
        uint256 completedCount = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].completed) {
                completedCount++;
            }
        }

        Task[] memory completedTasks = new Task[](completedCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (userTasks[msg.sender][i].completed) {
                completedTasks[currentIndex] = userTasks[msg.sender][i];
                currentIndex++;
            }
        }

        return completedTasks;
    }

    function getPendingTasks() external view returns (Task[] memory) {
        uint256 pendingCount = 0;
        
        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (!userTasks[msg.sender][i].completed) {
                pendingCount++;
            }
        }

        Task[] memory pendingTasks = new Task[](pendingCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < userTasks[msg.sender].length; i++) {
            if (!userTasks[msg.sender][i].completed) {
                pendingTasks[currentIndex] = userTasks[msg.sender][i];
                currentIndex++;
            }
        }

        return pendingTasks;
    }

    function getTaskCount(address user) external view returns (uint256) {
        return taskCount[user];
    }
}
