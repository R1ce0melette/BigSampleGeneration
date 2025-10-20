// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageWithLikes {
    struct Message {
        address sender;
        string text;
        uint256 timestamp;
        uint256 likes;
    }

    Message[] public messages;
    mapping(uint256 => mapping(address => bool)) public liked;

    event MessageSent(address indexed sender, uint256 indexed messageId, string text);
    event MessageLiked(address indexed liker, uint256 indexed messageId);

    function sendMessage(string calldata text) external {
        messages.push(Message({
            sender: msg.sender,
            text: text,
            timestamp: block.timestamp,
            likes: 0
        }));
        emit MessageSent(msg.sender, messages.length - 1, text);
    }

    function likeMessage(uint256 messageId) external {
        require(messageId < messages.length, "Invalid messageId");
        require(!liked[messageId][msg.sender], "Already liked");
        liked[messageId][msg.sender] = true;
        messages[messageId].likes += 1;
        emit MessageLiked(msg.sender, messageId);
    }

    function getMessage(uint256 messageId) external view returns (address, string memory, uint256, uint256) {
        require(messageId < messages.length, "Invalid messageId");
        Message storage m = messages[messageId];
        return (m.sender, m.text, m.timestamp, m.likes);
    }

    function getMessageCount() external view returns (uint256) {
        return messages.length;
    }
}
