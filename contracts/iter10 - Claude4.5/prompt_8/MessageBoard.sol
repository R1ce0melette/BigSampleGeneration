// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
    }

    uint256 public messageCount;
    mapping(uint256 => Message) public messages;

    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);

    function postMessage(string memory content) external {
        require(bytes(content).length > 0, "Message cannot be empty");
        require(bytes(content).length <= 1000, "Message too long");

        messageCount++;
        messages[messageCount] = Message({
            id: messageCount,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp
        });

        emit MessagePosted(messageCount, msg.sender, content, block.timestamp);
    }

    function getMessage(uint256 messageId) external view returns (
        uint256 id,
        address author,
        string memory content,
        uint256 timestamp
    ) {
        require(messageId > 0 && messageId <= messageCount, "Message does not exist");
        Message memory message = messages[messageId];
        return (message.id, message.author, message.content, message.timestamp);
    }

    function getLatestMessages(uint256 count) external view returns (Message[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > messageCount ? messageCount : count;
        Message[] memory latestMessages = new Message[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            latestMessages[i] = messages[messageCount - i];
        }

        return latestMessages;
    }

    function getMessagesByAuthor(address author) external view returns (uint256[] memory) {
        uint256 authorMessageCount = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == author) {
                authorMessageCount++;
            }
        }

        uint256[] memory authorMessageIds = new uint256[](authorMessageCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == author) {
                authorMessageIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return authorMessageIds;
    }
}
