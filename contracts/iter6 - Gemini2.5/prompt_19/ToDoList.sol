// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        string text;
        bool completed;
    }

    mapping(address => Todo[]) public userTodos;

    event TodoAdded(address indexed user, uint256 todoIndex, string text);
    event TodoToggled(address indexed user, uint256 todoIndex, bool completed);

    function addTodo(string memory _text) public {
        userTodos[msg.sender].push(Todo(_text, false));
        emit TodoAdded(msg.sender, userTodos[msg.sender].length - 1, _text);
    }

    function toggleTodo(uint256 _todoIndex) public {
        require(_todoIndex < userTodos[msg.sender].length, "Todo index out of bounds.");
        
        Todo storage todo = userTodos[msg.sender][_todoIndex];
        todo.completed = !todo.completed;

        emit TodoToggled(msg.sender, _todoIndex, todo.completed);
    }

    function getTodoCount(address _user) public view returns (uint256) {
        return userTodos[_user].length;
    }

    function getTodo(address _user, uint256 _todoIndex) public view returns (string memory, bool) {
        require(_todoIndex < userTodos[_user].length, "Todo index out of bounds.");
        Todo storage todo = userTodos[_user][_todoIndex];
        return (todo.text, todo.completed);
    }
}
