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

    function getTodos(address user) external view returns (Todo[] memory) {
        return todos[user];
    }
}
