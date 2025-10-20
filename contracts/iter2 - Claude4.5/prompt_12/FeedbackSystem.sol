// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeedbackSystem {
    struct Feedback {
        uint256 feedbackId;
        address user;
        uint8 rating;
        string comment;
        uint256 timestamp;
    }
    
    uint256 public feedbackCount;
    mapping(uint256 => Feedback) public feedbacks;
    mapping(address => uint256[]) public userFeedbacks;
    
    uint256 public totalRatings;
    uint256 public sumOfRatings;
    
    event FeedbackSubmitted(uint256 indexed feedbackId, address indexed user, uint8 rating, uint256 timestamp);
    
    function submitFeedback(uint8 _rating, string memory _comment) external {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(bytes(_comment).length > 0, "Comment cannot be empty");
        require(bytes(_comment).length <= 500, "Comment too long");
        
        feedbackCount++;
        
        feedbacks[feedbackCount] = Feedback({
            feedbackId: feedbackCount,
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });
        
        userFeedbacks[msg.sender].push(feedbackCount);
        
        totalRatings++;
        sumOfRatings += _rating;
        
        emit FeedbackSubmitted(feedbackCount, msg.sender, _rating, block.timestamp);
    }
    
    function getFeedback(uint256 _feedbackId) external view returns (
        uint256 feedbackId,
        address user,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(_feedbackId > 0 && _feedbackId <= feedbackCount, "Invalid feedback ID");
        Feedback memory feedback = feedbacks[_feedbackId];
        
        return (
            feedback.feedbackId,
            feedback.user,
            feedback.rating,
            feedback.comment,
            feedback.timestamp
        );
    }
    
    function getUserFeedbackCount(address _user) external view returns (uint256) {
        return userFeedbacks[_user].length;
    }
    
    function getUserFeedbackIds(address _user) external view returns (uint256[] memory) {
        return userFeedbacks[_user];
    }
    
    function getAverageRating() external view returns (uint256) {
        if (totalRatings == 0) {
            return 0;
        }
        return (sumOfRatings * 100) / totalRatings; // Returns rating * 100 for precision
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
        
        return (
            distribution[0],
            distribution[1],
            distribution[2],
            distribution[3],
            distribution[4]
        );
    }
    
    function getRecentFeedbacks(uint256 _count) external view returns (Feedback[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > feedbackCount ? feedbackCount : _count;
        Feedback[] memory recentFeedbacks = new Feedback[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentFeedbacks[i] = feedbacks[feedbackCount - i];
        }
        
        return recentFeedbacks;
    }
}
