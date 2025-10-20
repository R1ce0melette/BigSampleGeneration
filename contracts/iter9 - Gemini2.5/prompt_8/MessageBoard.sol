// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    Message[] public messages;

    event NewMessage(address indexed sender, string content, uint256 timestamp);

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

        emit NewMessage(msg.sender, _content, block.timestamp);
    }

    /**
     * @dev Retrieves the total number of messages on the board.
     * @return The total number of messages.
     */
    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }

    /**
     * @dev Retrieves a specific message by its index.
     * @param _index The index of the message to retrieve.
     * @return The sender, content, and timestamp of the message.
     */
    function getMessage(uint256 _index) public view returns (address, string memory, uint256) {
        require(_index < messages.length, "Message index out of bounds.");
        Message storage msgData = messages[_index];
        return (msgData.sender, msgData.content, msgData.timestamp);
    }
}
