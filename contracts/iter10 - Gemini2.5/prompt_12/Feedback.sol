// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feedback {
    struct FeedbackItem {
        address user;
        uint8 rating; // 1 to 5
        string comment;
        uint256 timestamp;
    }

    FeedbackItem[] public feedbackItems;
    mapping(address => bool) public hasGivenFeedback;

    event FeedbackGiven(address indexed user, uint8 rating, string comment);

    function giveFeedback(uint8 _rating, string memory _comment) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(!hasGivenFeedback[msg.sender], "You have already given feedback.");

        feedbackItems.push(FeedbackItem(msg.sender, _rating, _comment, block.timestamp));
        hasGivenFeedback[msg.sender] = true;

        emit FeedbackGiven(msg.sender, _rating, _comment);
    }

    function getFeedbackCount() public view returns (uint256) {
        return feedbackItems.length;
    }

    function getFeedback(uint256 _index) public view returns (address, uint8, string memory, uint256) {
        require(_index < feedbackItems.length, "Feedback index out of bounds.");
        FeedbackItem storage item = feedbackItems[_index];
        return (item.user, item.rating, item.comment, item.timestamp);
    }
}
