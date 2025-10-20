// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ToDoList
 * @dev A contract that allows users to create and manage their personal to-do lists on-chain.
 */
contract ToDoList {
    // Struct to represent a single to-do item.
    struct ToDoItem {
        string text;
        bool isCompleted;
    }

    // Mapping from a user's address to their list of to-do items.
    mapping(address => ToDoItem[]) private userToDoLists;

    /**
     * @dev Emitted when a new to-do item is added.
     * @param user The address of the user.
     * @param index The index of the new to-do item in the user's list.
     * @param text The content of the to-do item.
     */
    event ToDoItemAdded(address indexed user, uint256 index, string text);

    /**
     * @dev Emitted when a to-do item is marked as completed.
     * @param user The address of the user.
     * @param index The index of the completed to-do item.
     */
    event ToDoItemCompleted(address indexed user, uint256 index);

    /**
     * @dev Adds a new to-do item to the caller's list.
     * @param _text The text of the to-do item.
     */
    function addToDo(string memory _text) public {
        require(bytes(_text).length > 0, "ToDoList: To-do text cannot be empty.");
        
        ToDoItem[] storage toDoList = userToDoLists[msg.sender];
        toDoList.push(ToDoItem({
            text: _text,
            isCompleted: false
        }));

        emit ToDoItemAdded(msg.sender, toDoList.length - 1, _text);
    }

    /**
     * @dev Marks a to-do item as completed.
     * @param _index The index of the to-do item to complete.
     */
    function completeToDo(uint256 _index) public {
        ToDoItem[] storage toDoList = userToDoLists[msg.sender];
        require(_index < toDoList.length, "ToDoList: Index out of bounds.");
        require(!toDoList[_index].isCompleted, "ToDoList: To-do item is already completed.");

        toDoList[_index].isCompleted = true;
        emit ToDoItemCompleted(msg.sender, _index);
    }

    /**
     * @dev Retrieves a specific to-do item from the caller's list.
     * @param _index The index of the to-do item.
     * @return The text and completion status of the to-do item.
     */
    function getToDo(uint256 _index) public view returns (string memory, bool) {
        ToDoItem[] storage toDoList = userToDoLists[msg.sender];
        require(_index < toDoList.length, "ToDoList: Index out of bounds.");
        
        ToDoItem storage item = toDoList[_index];
        return (item.text, item.isCompleted);
    }

    /**
     * @dev Returns the number of to-do items in the caller's list.
     * @return The total count of to-do items for the user.
     */
    function getToDoCount() public view returns (uint256) {
        return userToDoLists[msg.sender].length;
    }
}
