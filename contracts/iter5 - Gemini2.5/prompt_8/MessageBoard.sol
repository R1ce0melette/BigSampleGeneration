// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MessageBoard
 * @dev A contract that allows users to post and view messages with timestamps.
 */
contract MessageBoard {

    // Structure to represent a single message.
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
    }

    // An array to store all messages.
    Message[] public messages;
    // A counter to generate unique message IDs.
    uint256 private nextMessageId;

    /**
     * @dev Event emitted when a new message is posted.
     * @param messageId The unique ID of the message.
     * @param sender The address of the user who posted the message.
     * @param content The content of the message.
     * @param timestamp The timestamp when the message was posted.
     */
    event MessagePosted(
        uint256 indexed messageId,
        address indexed sender,
        string content,
        uint256 timestamp
    );

    /**
     * @dev Posts a new message to the board.
     * - The message content cannot be empty.
     * @param _content The content of the message to be posted.
     */
    function postMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");

        uint256 messageId = nextMessageId;
        messages.push(Message({
            id: messageId,
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        }));

        nextMessageId++;
        emit MessagePosted(messageId, msg.sender, _content, block.timestamp);
    }

    /**
     * @dev Retrieves a message by its ID.
     * @param _messageId The ID of the message to retrieve.
     * @return A tuple containing the message's ID, sender, content, and timestamp.
     */
    function getMessage(uint256 _messageId) public view returns (uint256, address, string memory, uint256) {
        require(_messageId < messages.length, "Message with this ID does not exist.");
        
        Message storage msgData = messages[_messageId];
        return (msgData.id, msgData.sender, msgData.content, msgData.timestamp);
    }

    /**
     * @dev Returns the total number of messages posted on the board.
     * @return The total count of messages.
     */
    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
