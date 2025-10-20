// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feedback {
    struct Review {
        string feedback;
        uint8 rating;
    }

    mapping(address => Review[]) public reviews;

    event FeedbackSubmitted(address indexed user, string feedback, uint8 rating);

    function submitFeedback(string calldata feedback, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating must be 1-5");
        reviews[msg.sender].push(Review(feedback, rating));
        emit FeedbackSubmitted(msg.sender, feedback, rating);
    }

    function getReview(address user, uint256 index) external view returns (string memory, uint8) {
        require(index < reviews[user].length, "Invalid index");
        Review storage r = reviews[user][index];
        return (r.feedback, r.rating);
    }

    function getReviewCount(address user) external view returns (uint256) {
        return reviews[user].length;
    }
}
