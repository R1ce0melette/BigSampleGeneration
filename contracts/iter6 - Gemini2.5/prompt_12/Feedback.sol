// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feedback {
    struct Review {
        address reviewer;
        uint8 rating; // 1 to 5
        string comment;
    }

    Review[] public reviews;
    mapping(address => bool) public hasReviewed;

    event NewReview(address indexed reviewer, uint8 rating, string comment);

    function leaveFeedback(uint8 _rating, string memory _comment) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(!hasReviewed[msg.sender], "You have already submitted feedback.");

        reviews.push(Review(msg.sender, _rating, _comment));
        hasReviewed[msg.sender] = true;

        emit NewReview(msg.sender, _rating, _comment);
    }

    function getReviewCount() public view returns (uint256) {
        return reviews.length;
    }

    function getReview(uint256 _index) public view returns (address, uint8, string memory) {
        require(_index < reviews.length, "Review index out of bounds.");
        Review storage reviewData = reviews[_index];
        return (reviewData.reviewer, reviewData.rating, reviewData.comment);
    }
}
