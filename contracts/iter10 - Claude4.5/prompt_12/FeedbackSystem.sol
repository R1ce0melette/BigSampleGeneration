// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeedbackSystem {
    struct Feedback {
        uint256 id;
        address user;
        uint8 rating;
        string comment;
        uint256 timestamp;
    }

    uint256 public feedbackCount;
    mapping(uint256 => Feedback) public feedbacks;
    mapping(address => uint256[]) public userFeedbacks;
    
    uint256 public totalRating;
    uint256 public ratingCount;

    event FeedbackSubmitted(uint256 indexed feedbackId, address indexed user, uint8 rating, uint256 timestamp);

    function submitFeedback(uint8 rating, string memory comment) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(bytes(comment).length > 0, "Comment cannot be empty");
        require(bytes(comment).length <= 500, "Comment too long");

        feedbackCount++;
        
        feedbacks[feedbackCount] = Feedback({
            id: feedbackCount,
            user: msg.sender,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp
        });

        userFeedbacks[msg.sender].push(feedbackCount);
        
        totalRating += rating;
        ratingCount++;

        emit FeedbackSubmitted(feedbackCount, msg.sender, rating, block.timestamp);
    }

    function getFeedback(uint256 feedbackId) external view returns (
        uint256 id,
        address user,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(feedbackId > 0 && feedbackId <= feedbackCount, "Feedback does not exist");
        Feedback memory feedback = feedbacks[feedbackId];
        return (feedback.id, feedback.user, feedback.rating, feedback.comment, feedback.timestamp);
    }

    function getUserFeedbackIds(address user) external view returns (uint256[] memory) {
        return userFeedbacks[user];
    }

    function getAverageRating() external view returns (uint256) {
        if (ratingCount == 0) {
            return 0;
        }
        return (totalRating * 100) / ratingCount; // Returns rating * 100 (e.g., 350 = 3.5 stars)
    }

    function getLatestFeedbacks(uint256 count) external view returns (Feedback[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > feedbackCount ? feedbackCount : count;
        Feedback[] memory latestFeedbacks = new Feedback[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            latestFeedbacks[i] = feedbacks[feedbackCount - i];
        }

        return latestFeedbacks;
    }

    function getRatingDistribution() external view returns (
        uint256 oneStar,
        uint256 twoStar,
        uint256 threeStar,
        uint256 fourStar,
        uint256 fiveStar
    ) {
        uint256[5] memory distribution;
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            uint8 rating = feedbacks[i].rating;
            distribution[rating - 1]++;
        }

        return (distribution[0], distribution[1], distribution[2], distribution[3], distribution[4]);
    }
}
