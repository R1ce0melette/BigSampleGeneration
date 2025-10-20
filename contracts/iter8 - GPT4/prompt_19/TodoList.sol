// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        string text;
        bool completed;
    }

    mapping(address => Todo[]) public todos;

    event TodoAdded(address indexed user, uint256 index, string text);
    event TodoCompleted(address indexed user, uint256 index);
    event TodoRemoved(address indexed user, uint256 index);

    function addTodo(string calldata text) external {
        todos[msg.sender].push(Todo(text, false));
        emit TodoAdded(msg.sender, todos[msg.sender].length - 1, text);
    }

    function completeTodo(uint256 index) external {
        require(index < todos[msg.sender].length, "Invalid index");
        require(!todos[msg.sender][index].completed, "Already completed");
        todos[msg.sender][index].completed = true;
        emit TodoCompleted(msg.sender, index);
    }

    function removeTodo(uint256 index) external {
        require(index < todos[msg.sender].length, "Invalid index");
        uint256 last = todos[msg.sender].length - 1;
        if (index != last) {
            todos[msg.sender][index] = todos[msg.sender][last];
        }
        todos[msg.sender].pop();
        emit TodoRemoved(msg.sender, index);
    }

    function getTodos(address user) external view returns (Todo[] memory) {
        return todos[user];
    }
}
