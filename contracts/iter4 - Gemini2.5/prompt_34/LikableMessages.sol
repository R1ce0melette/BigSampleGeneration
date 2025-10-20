// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikableMessages {
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
        uint256 likes;
    }

    Message[] public messages;
    uint256 public messageCounter;
    mapping(uint256 => mapping(address => bool)) public hasLiked;

    event MessagePosted(uint256 indexed id, address indexed sender, string content);
    event MessageLiked(uint256 indexed messageId, address indexed liker);

    function postMessage(string memory _content) public {
        messageCounter++;
        messages.push(Message(messageCounter, msg.sender, _content, block.timestamp, 0));
        emit MessagePosted(messageCounter, msg.sender, _content);
    }

    function likeMessage(uint256 _messageId) public {
        require(_messageId > 0 && _messageId <= messageCounter, "Message does not exist.");
        require(!hasLiked[_messageId][msg.sender], "You have already liked this message.");
        
        Message storage message = messages[_messageId - 1]; // Adjust for 0-based index
        require(msg.sender != message.sender, "You cannot like your own message.");

        hasLiked[_messageId][msg.sender] = true;
        message.likes++;
        emit MessageLiked(_messageId, msg.sender);
    }

    function getMessage(uint256 _messageId) public view returns (uint256, address, string memory, uint256, uint256) {
        require(_messageId > 0 && _messageId <= messageCounter, "Message does not exist.");
        Message storage msgStruct = messages[_messageId - 1];
        return (msgStruct.id, msgStruct.sender, msgStruct.content, msgStruct.timestamp, msgStruct.likes);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
