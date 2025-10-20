// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        string text;
        bool completed;
    }

    mapping(address => Todo[]) public todos;

    function addTodo(string calldata text) external {
        todos[msg.sender].push(Todo(text, false));
    }

    function completeTodo(uint256 index) external {
        require(index < todos[msg.sender].length, "Invalid index");
        todos[msg.sender][index].completed = true;
    }

    function getTodoCount(address user) external view returns (uint256) {
        return todos[user].length;
    }

    function getTodo(address user, uint256 index) external view returns (string memory, bool) {
        Todo storage t = todos[user][index];
        return (t.text, t.completed);
    }
}
