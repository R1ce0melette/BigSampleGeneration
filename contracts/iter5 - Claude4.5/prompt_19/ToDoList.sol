// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        uint256 id;
        string content;
        bool completed;
        uint256 createdTime;
        uint256 completedTime;
    }
    
    mapping(address => Todo[]) public userTodos;
    mapping(address => uint256) public userTodoCount;
    
    event TodoCreated(address indexed user, uint256 indexed todoId, string content);
    event TodoCompleted(address indexed user, uint256 indexed todoId);
    event TodoUncompleted(address indexed user, uint256 indexed todoId);
    event TodoUpdated(address indexed user, uint256 indexed todoId, string newContent);
    event TodoDeleted(address indexed user, uint256 indexed todoId);
    
    function createTodo(string memory _content) external {
        require(bytes(_content).length > 0, "Content cannot be empty");
        
        uint256 todoId = userTodos[msg.sender].length;
        
        userTodos[msg.sender].push(Todo({
            id: todoId,
            content: _content,
            completed: false,
            createdTime: block.timestamp,
            completedTime: 0
        }));
        
        userTodoCount[msg.sender]++;
        
        emit TodoCreated(msg.sender, todoId, _content);
    }
    
    function completeTodo(uint256 _todoId) external {
        require(_todoId < userTodos[msg.sender].length, "Todo does not exist");
        
        Todo storage todo = userTodos[msg.sender][_todoId];
        require(!todo.completed, "Todo is already completed");
        
        todo.completed = true;
        todo.completedTime = block.timestamp;
        
        emit TodoCompleted(msg.sender, _todoId);
    }
    
    function uncompleteTodo(uint256 _todoId) external {
        require(_todoId < userTodos[msg.sender].length, "Todo does not exist");
        
        Todo storage todo = userTodos[msg.sender][_todoId];
        require(todo.completed, "Todo is not completed");
        
        todo.completed = false;
        todo.completedTime = 0;
        
        emit TodoUncompleted(msg.sender, _todoId);
    }
    
    function updateTodo(uint256 _todoId, string memory _newContent) external {
        require(_todoId < userTodos[msg.sender].length, "Todo does not exist");
        require(bytes(_newContent).length > 0, "Content cannot be empty");
        
        Todo storage todo = userTodos[msg.sender][_todoId];
        todo.content = _newContent;
        
        emit TodoUpdated(msg.sender, _todoId, _newContent);
    }
    
    function deleteTodo(uint256 _todoId) external {
        require(_todoId < userTodos[msg.sender].length, "Todo does not exist");
        
        uint256 lastIndex = userTodos[msg.sender].length - 1;
        
        if (_todoId != lastIndex) {
            userTodos[msg.sender][_todoId] = userTodos[msg.sender][lastIndex];
            userTodos[msg.sender][_todoId].id = _todoId;
        }
        
        userTodos[msg.sender].pop();
        userTodoCount[msg.sender]--;
        
        emit TodoDeleted(msg.sender, _todoId);
    }
    
    function getTodo(uint256 _todoId) external view returns (
        uint256 id,
        string memory content,
        bool completed,
        uint256 createdTime,
        uint256 completedTime
    ) {
        require(_todoId < userTodos[msg.sender].length, "Todo does not exist");
        
        Todo memory todo = userTodos[msg.sender][_todoId];
        
        return (
            todo.id,
            todo.content,
            todo.completed,
            todo.createdTime,
            todo.completedTime
        );
    }
    
    function getAllTodos() external view returns (Todo[] memory) {
        return userTodos[msg.sender];
    }
    
    function getUserTodos(address _user) external view returns (Todo[] memory) {
        return userTodos[_user];
    }
    
    function getCompletedTodos() external view returns (Todo[] memory) {
        uint256 completedCount = 0;
        
        for (uint256 i = 0; i < userTodos[msg.sender].length; i++) {
            if (userTodos[msg.sender][i].completed) {
                completedCount++;
            }
        }
        
        Todo[] memory completedTodos = new Todo[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTodos[msg.sender].length; i++) {
            if (userTodos[msg.sender][i].completed) {
                completedTodos[index] = userTodos[msg.sender][i];
                index++;
            }
        }
        
        return completedTodos;
    }
    
    function getPendingTodos() external view returns (Todo[] memory) {
        uint256 pendingCount = 0;
        
        for (uint256 i = 0; i < userTodos[msg.sender].length; i++) {
            if (!userTodos[msg.sender][i].completed) {
                pendingCount++;
            }
        }
        
        Todo[] memory pendingTodos = new Todo[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userTodos[msg.sender].length; i++) {
            if (!userTodos[msg.sender][i].completed) {
                pendingTodos[index] = userTodos[msg.sender][i];
                index++;
            }
        }
        
        return pendingTodos;
    }
    
    function getTodoCount() external view returns (uint256) {
        return userTodos[msg.sender].length;
    }
}
