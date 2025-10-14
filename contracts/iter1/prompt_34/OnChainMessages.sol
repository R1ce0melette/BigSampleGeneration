// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OnChainMessages {
    struct Message {
        address sender;
        string text;
        uint256 timestamp;
        uint256 likes;
    }

    Message[] public messages;
    mapping(uint256 => mapping(address => bool)) public liked;

    event MessageSent(address indexed sender, uint256 indexed messageId, string text);
    event MessageLiked(address indexed user, uint256 indexed messageId);

    function sendMessage(string calldata text) external {
        require(bytes(text).length > 0, "Message required");
        messages.push(Message(msg.sender, text, block.timestamp, 0));
        emit MessageSent(msg.sender, messages.length - 1, text);
    }

    function likeMessage(uint256 messageId) external {
        require(messageId < messages.length, "Invalid message");
        require(!liked[messageId][msg.sender], "Already liked");
        liked[messageId][msg.sender] = true;
        messages[messageId].likes += 1;
        emit MessageLiked(msg.sender, messageId);
    }

    function getMessage(uint256 messageId) external view returns (address, string memory, uint256, uint256) {
        require(messageId < messages.length, "Invalid message");
        Message storage m = messages[messageId];
        return (m.sender, m.text, m.timestamp, m.likes);
    }

    function getMessagesCount() external view returns (uint256) {
        return messages.length;
    }
}
