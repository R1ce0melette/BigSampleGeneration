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
    mapping(uint256 => mapping(address => bool)) public hasLiked;

    event MessageSent(address indexed sender, uint256 indexed id, string text);
    event MessageLiked(address indexed liker, uint256 indexed id);

    function sendMessage(string calldata text) external {
        messages.push(Message(msg.sender, text, block.timestamp, 0));
        emit MessageSent(msg.sender, messages.length - 1, text);
    }

    function likeMessage(uint256 id) external {
        require(id < messages.length, "Invalid message");
        require(!hasLiked[id][msg.sender], "Already liked");
        hasLiked[id][msg.sender] = true;
        messages[id].likes++;
        emit MessageLiked(msg.sender, id);
    }

    function getMessage(uint256 id) external view returns (address, string memory, uint256, uint256) {
        require(id < messages.length, "Invalid message");
        Message storage m = messages[id];
        return (m.sender, m.text, m.timestamp, m.likes);
    }

    function getMessageCount() external view returns (uint256) {
        return messages.length;
    }
}
