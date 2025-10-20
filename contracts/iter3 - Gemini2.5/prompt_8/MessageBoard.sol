// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MessageBoard
 * @dev A contract that allows users to store and view messages with timestamps.
 */
contract MessageBoard {
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
    }

    // An array to store all messages
    Message[] public messages;
    // A counter for generating unique message IDs
    uint256 private _messageIdCounter;

    /**
     * @dev Emitted when a new message is posted.
     * @param id The unique ID of the message.
     * @param sender The address of the message sender.
     * @param content The content of the message.
     * @param timestamp The timestamp when the message was posted.
     */
    event MessagePosted(
        uint256 indexed id,
        address indexed sender,
        string content,
        uint256 timestamp
    );

    /**
     * @dev Allows anyone to post a message to the board.
     * The message content cannot be empty.
     * @param _content The content of the message to be posted.
     */
    function postMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");

        _messageIdCounter++;
        uint256 newMessageId = _messageIdCounter;
        
        Message memory newMessage = Message({
            id: newMessageId,
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        });

        messages.push(newMessage);

        emit MessagePosted(newMessageId, msg.sender, _content, block.timestamp);
    }

    /**
     * @dev Retrieves a message by its ID.
     * @param _id The ID of the message to retrieve.
     * @return A tuple containing the message's ID, sender, content, and timestamp.
     * Note: This function will revert if the ID is out of bounds because `messages`
     * is a public array, and Solidity's auto-generated getter will handle the check.
     */
    function getMessage(uint256 _id) public view returns (uint256, address, string memory, uint256) {
        // Message IDs start from 1, but array is 0-indexed.
        require(_id > 0 && _id <= messages.length, "Message ID is out of bounds.");
        Message storage message = messages[_id - 1];
        return (message.id, message.sender, message.content, message.timestamp);
    }

    /**
     * @dev Returns the total number of messages posted on the board.
     * @return The total count of messages.
     */
    function getTotalMessages() public view returns (uint256) {
        return messages.length;
    }
}
