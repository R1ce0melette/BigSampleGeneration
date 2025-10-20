// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feedback {
    struct Review {
        address user;
        string feedback;
        uint8 rating;
    }

    Review[] public reviews;

    event FeedbackSubmitted(address indexed user, string feedback, uint8 rating);

    function submitFeedback(string calldata feedback, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating must be 1-5");
        reviews.push(Review({
            user: msg.sender,
            feedback: feedback,
            rating: rating
        }));
        emit FeedbackSubmitted(msg.sender, feedback, rating);
    }

    function getReview(uint256 index) external view returns (address, string memory, uint8) {
        require(index < reviews.length, "Invalid index");
        Review storage r = reviews[index];
        return (r.user, r.feedback, r.rating);
    }

    function getReviewCount() external view returns (uint256) {
        return reviews.length;
    }
}
