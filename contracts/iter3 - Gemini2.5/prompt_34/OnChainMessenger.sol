// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainMessenger
 * @dev A contract that allows users to send on-chain messages which can be liked by others.
 */
contract OnChainMessenger {
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
        uint256 likeCount;
        mapping(address => bool) hasLiked;
    }

    uint256 private _messageIdCounter;
    Message[] public messages;

    /**
     * @dev Emitted when a new message is sent.
     * @param messageId The unique ID of the message.
     * @param sender The address of the message sender.
     * @param content The content of the message.
     */
    event MessageSent(uint256 indexed messageId, address indexed sender, string content);

    /**
     * @dev Emitted when a message is liked.
     * @param messageId The ID of the liked message.
     * @param liker The address of the user who liked the message.
     */
    event MessageLiked(uint256 indexed messageId, address indexed liker);

    /**
     * @dev Sends a new message.
     * @param _content The content of the message.
     */
    function sendMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");

        _messageIdCounter++;
        Message storage newMessage = messages.push();
        newMessage.id = _messageIdCounter;
        newMessage.sender = msg.sender;
        newMessage.content = _content;
        newMessage.timestamp = block.timestamp;

        emit MessageSent(_messageIdCounter, msg.sender, _content);
    }

    /**
     * @dev Allows a user to like a message.
     * A user cannot like their own message or like the same message twice.
     * @param _messageId The ID of the message to like.
     */
    function likeMessage(uint256 _messageId) public {
        require(_messageId > 0 && _messageId <= messages.length, "Invalid message ID.");
        
        Message storage message = messages[_messageId - 1];
        require(msg.sender != message.sender, "You cannot like your own message.");
        require(!message.hasLiked[msg.sender], "You have already liked this message.");

        message.hasLiked[msg.sender] = true;
        message.likeCount++;

        emit MessageLiked(_messageId, msg.sender);
    }

    /**
     * @dev Retrieves the details of a specific message.
     * @param _messageId The ID of the message.
     * @return A tuple containing the message's ID, sender, content, timestamp, and like count.
     */
    function getMessage(uint256 _messageId) public view returns (uint256, address, string memory, uint256, uint256) {
        require(_messageId > 0 && _messageId <= messages.length, "Invalid message ID.");
        Message storage msg = messages[_messageId - 1];
        return (msg.id, msg.sender, msg.content, msg.timestamp, msg.likeCount);
    }

    /**
     * @dev Returns the total number of messages sent.
     */
    function getTotalMessages() public view returns (uint256) {
        return messages.length;
    }
}
