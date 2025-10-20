// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MessageBoard
 * @dev A contract that allows users to post and view messages with timestamps.
 */
contract MessageBoard {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    Message[] public messages;

    event MessagePosted(address indexed sender, string content, uint256 timestamp);

    /**
     * @dev Posts a new message to the board.
     * @param _content The content of the message.
     */
    function postMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");
        messages.push(Message({
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        }));
        emit MessagePosted(msg.sender, _content, block.timestamp);
    }

    /**
     * @dev Returns the total number of messages posted.
     * @return The total number of messages.
     */
    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }

    /**
     * @dev Retrieves a message by its index.
     * @param _index The index of the message in the messages array.
     * @return The sender, content, and timestamp of the message.
     */
    function getMessage(uint256 _index) public view returns (address, string memory, uint256) {
        require(_index < messages.length, "Message index out of bounds.");
        Message storage msgData = messages[_index];
        return (msgData.sender, msgData.content, msgData.timestamp);
    }
}
