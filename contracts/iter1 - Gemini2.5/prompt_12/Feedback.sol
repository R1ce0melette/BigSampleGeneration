// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feedback {

    struct FeedbackItem {
        address user;
        uint8 rating;
        string comment;
    }

    FeedbackItem[] public feedbackLog;
    mapping(address => bool) public hasSubmitted;

    event FeedbackSubmitted(address indexed user, uint8 rating, string comment);

    function submitFeedback(uint8 _rating, string calldata _comment) public {
        require(!hasSubmitted[msg.sender], "You have already submitted feedback.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        feedbackLog.push(FeedbackItem({
            user: msg.sender,
            rating: _rating,
            comment: _comment
        }));

        hasSubmitted[msg.sender] = true;

        emit FeedbackSubmitted(msg.sender, _rating, _comment);
    }

    function getFeedback(uint256 _index) public view returns (address, uint8, string memory) {
        require(_index < feedbackLog.length, "Feedback index out of bounds.");
        FeedbackItem storage item = feedbackLog[_index];
        return (item.user, item.rating, item.comment);
    }

    function getFeedbackCount() public view returns (uint256) {
        return feedbackLog.length;
    }
}
