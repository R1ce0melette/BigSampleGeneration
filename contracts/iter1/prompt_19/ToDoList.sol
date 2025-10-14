// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ToDoList {
    struct Task {
        string description;
        bool completed;
    }

    mapping(address => Task[]) private userTasks;

    event TaskAdded(address indexed user, string description);
    event TaskCompleted(address indexed user, uint256 index);
    event TaskRemoved(address indexed user, uint256 index);

    function addTask(string calldata description) external {
        require(bytes(description).length > 0, "Description required");
        userTasks[msg.sender].push(Task(description, false));
        emit TaskAdded(msg.sender, description);
    }

    function completeTask(uint256 index) external {
        require(index < userTasks[msg.sender].length, "Invalid index");
        userTasks[msg.sender][index].completed = true;
        emit TaskCompleted(msg.sender, index);
    }

    function removeTask(uint256 index) external {
        require(index < userTasks[msg.sender].length, "Invalid index");
        for (uint i = index; i < userTasks[msg.sender].length - 1; i++) {
            userTasks[msg.sender][i] = userTasks[msg.sender][i + 1];
        }
        userTasks[msg.sender].pop();
        emit TaskRemoved(msg.sender, index);
    }

    function getTasks(address user) external view returns (Task[] memory) {
        return userTasks[user];
    }
}
