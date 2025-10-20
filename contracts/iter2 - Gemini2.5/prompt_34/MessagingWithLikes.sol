// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessagingWithLikes {
    struct Message {
        uint256 id;
        string content;
        address sender;
        uint256 likes;
        mapping(address => bool) hasLiked;
    }

    Message[] public messages;
    uint256 public messageCount;

    event MessageSent(uint256 indexed messageId, string content, address indexed sender);
    event MessageLiked(uint256 indexed messageId, address indexed liker);

    /**
     * @dev Sends a new message.
     * @param _content The content of the message.
     */
    function sendMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");
        
        messageCount++;
        messages.push(Message({
            id: messageCount,
            content: _content,
            sender: msg.sender,
            likes: 0
        }));

        emit MessageSent(messageCount, _content, msg.sender);
    }

    /**
     * @dev Allows a user to like a message.
     * @param _messageId The ID of the message to like.
     */
    function likeMessage(uint256 _messageId) public {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist.");
        
        Message storage msgToLike = messages[_messageId - 1];
        require(msgToLike.sender != msg.sender, "You cannot like your own message.");
        require(!msgToLike.hasLiked[msg.sender], "You have already liked this message.");

        msgToLike.hasLiked[msg.sender] = true;
        msgToLike.likes++;

        emit MessageLiked(_messageId, msg.sender);
    }

    /**
     * @dev Retrieves a message by its ID.
     * @param _messageId The ID of the message.
     * @return The message content, sender address, and number of likes.
     */
    function getMessage(uint256 _messageId) public view returns (string memory, address, uint256) {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist.");
        Message storage msgData = messages[_messageId - 1];
        return (msgData.content, msgData.sender, msgData.likes);
    }
}
