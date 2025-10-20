// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feedback {
    struct FeedbackItem {
        address user;
        uint8 rating; // 1 to 5 stars
        string comment;
        uint256 timestamp;
    }

    FeedbackItem[] public feedbackItems;
    mapping(address => bool) public hasGivenFeedback;

    event FeedbackSubmitted(address indexed user, uint8 rating, string comment);

    /**
     * @dev Submits feedback with a rating and a comment.
     * @param _rating The rating from 1 to 5.
     * @param _comment The feedback comment.
     */
    function submitFeedback(uint8 _rating, string memory _comment) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(!hasGivenFeedback[msg.sender], "You have already submitted feedback.");

        feedbackItems.push(FeedbackItem({
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        }));

        hasGivenFeedback[msg.sender] = true;
        emit FeedbackSubmitted(msg.sender, _rating, _comment);
    }

    /**
     * @dev Retrieves the total number of feedback items.
     * @return The total number of feedback items.
     */
    function getFeedbackCount() public view returns (uint256) {
        return feedbackItems.length;
    }

    /**
     * @dev Retrieves a specific feedback item by its index.
     * @param _index The index of the feedback item to retrieve.
     * @return The user, rating, comment, and timestamp of the feedback.
     */
    function getFeedback(uint256 _index) public view returns (address, uint8, string memory, uint256) {
        require(_index < feedbackItems.length, "Feedback index out of bounds.");
        FeedbackItem storage item = feedbackItems[_index];
        return (item.user, item.rating, item.comment, item.timestamp);
    }
}
