// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        string text;
        bool completed;
    }

    mapping(address => Todo[]) public userTodos;

    event TodoCreated(address indexed user, uint256 index, string text);
    event TodoToggled(address indexed user, uint256 index, bool completed);

    function createTodo(string memory _text) public {
        userTodos[msg.sender].push(Todo(_text, false));
        emit TodoCreated(msg.sender, userTodos[msg.sender].length - 1, _text);
    }

    function toggleTodo(uint256 _index) public {
        Todo storage todo = userTodos[msg.sender][_index];
        todo.completed = !todo.completed;
        emit TodoToggled(msg.sender, _index, todo.completed);
    }

    function getTodo(uint256 _index) public view returns (string memory, bool) {
        Todo storage todo = userTodos[msg.sender][_index];
        return (todo.text, todo.completed);
    }

    function getTodoCount() public view returns (uint256) {
        return userTodos[msg.sender].length;
    }
}
