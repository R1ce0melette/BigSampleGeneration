// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        string text;
        bool completed;
    }

    mapping(address => Todo[]) private todos;

    event TodoAdded(address indexed user, uint256 index, string text);
    event TodoCompleted(address indexed user, uint256 index);
    event TodoRemoved(address indexed user, uint256 index);

    function addTodo(string calldata text) external {
        todos[msg.sender].push(Todo({text: text, completed: false}));
        emit TodoAdded(msg.sender, todos[msg.sender].length - 1, text);
    }

    function completeTodo(uint256 index) external {
        require(index < todos[msg.sender].length, "Invalid index");
        todos[msg.sender][index].completed = true;
        emit TodoCompleted(msg.sender, index);
    }

    function removeTodo(uint256 index) external {
        require(index < todos[msg.sender].length, "Invalid index");
        for (uint256 i = index; i < todos[msg.sender].length - 1; i++) {
            todos[msg.sender][i] = todos[msg.sender][i + 1];
        }
        todos[msg.sender].pop();
        emit TodoRemoved(msg.sender, index);
    }

    function getTodos(address user) external view returns (Todo[] memory) {
        return todos[user];
    }
}
