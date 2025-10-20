// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        string content;
        bool isCompleted;
    }

    mapping(address => Task[]) public userTasks;

    event TaskAdded(address indexed user, uint taskId, string content);
    event TaskCompleted(address indexed user, uint taskId);

    function addTask(string memory _content) public {
        require(bytes(_content).length > 0, "Task content cannot be empty.");
        userTasks[msg.sender].push(Task(_content, false));
        emit TaskAdded(msg.sender, userTasks[msg.sender].length - 1, _content);
    }

    function completeTask(uint _taskId) public {
        require(_taskId < userTasks[msg.sender].length, "Task ID is out of bounds.");
        Task storage task = userTasks[msg.sender][_taskId];
        require(!task.isCompleted, "Task is already completed.");
        
        task.isCompleted = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    function getTask(uint _taskId) public view returns (string memory, bool) {
        require(_taskId < userTasks[msg.sender].length, "Task ID is out of bounds.");
        Task storage task = userTasks[msg.sender][_taskId];
        return (task.content, task.isCompleted);
    }

    function getTaskCount() public view returns (uint) {
        return userTasks[msg.sender].length;
    }
}
