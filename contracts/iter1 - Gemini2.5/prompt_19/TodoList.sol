// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {

    struct TodoItem {
        string task;
        bool isDone;
    }

    mapping(address => TodoItem[]) public userTodos;

    event TodoAdded(address indexed user, uint256 todoId, string task);
    event TodoToggled(address indexed user, uint256 todoId, bool isDone);

    function addTodo(string calldata _task) public {
        uint256 todoId = userTodos[msg.sender].length;
        userTodos[msg.sender].push(TodoItem({
            task: _task,
            isDone: false
        }));
        emit TodoAdded(msg.sender, todoId, _task);
    }

    function toggleTodoStatus(uint256 _todoId) public {
        require(_todoId < userTodos[msg.sender].length, "Todo item does not exist.");
        
        TodoItem storage todo = userTodos[msg.sender][_todoId];
        todo.isDone = !todo.isDone;
        
        emit TodoToggled(msg.sender, _todoId, todo.isDone);
    }

    function getMyTodos() public view returns (TodoItem[] memory) {
        return userTodos[msg.sender];
    }

    function getTodoCount() public view returns (uint256) {
        return userTodos[msg.sender].length;
    }
}
