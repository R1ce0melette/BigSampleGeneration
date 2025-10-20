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
    
    function submitFeedback(uint8 _rating, string memory _comment) external {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(bytes(_comment).length > 0, "Comment cannot be empty");
        
        feedbackCount++;
        
        feedbacks[feedbackCount] = Feedback({
            id: feedbackCount,
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });
        
        userFeedbacks[msg.sender].push(feedbackCount);
        
        totalRating += _rating;
        ratingCount++;
        
        emit FeedbackSubmitted(feedbackCount, msg.sender, _rating, block.timestamp);
    }
    
    function getFeedback(uint256 _feedbackId) external view returns (
        uint256 id,
        address user,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(_feedbackId > 0 && _feedbackId <= feedbackCount, "Feedback does not exist");
        
        Feedback memory feedback = feedbacks[_feedbackId];
        
        return (
            feedback.id,
            feedback.user,
            feedback.rating,
            feedback.comment,
            feedback.timestamp
        );
    }
    
    function getUserFeedbackIds(address _user) external view returns (uint256[] memory) {
        return userFeedbacks[_user];
    }
    
    function getAverageRating() external view returns (uint256) {
        if (ratingCount == 0) {
            return 0;
        }
        return (totalRating * 100) / ratingCount; // Returns average * 100 for precision
    }
    
    function getAllFeedbacks() external view returns (Feedback[] memory) {
        Feedback[] memory allFeedbacks = new Feedback[](feedbackCount);
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            allFeedbacks[i - 1] = feedbacks[i];
        }
        
        return allFeedbacks;
    }
    
    function getFeedbacksByRating(uint8 _rating) external view returns (uint256[] memory) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        
        uint256 count = 0;
        for (uint256 i = 1; i <= feedbackCount; i++) {
            if (feedbacks[i].rating == _rating) {
                count++;
            }
        }
        
        uint256[] memory ratingFeedbackIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            if (feedbacks[i].rating == _rating) {
                ratingFeedbackIds[index] = i;
                index++;
            }
        }
        
        return ratingFeedbackIds;
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
            distribution[feedbacks[i].rating - 1]++;
        }
        
        return (
            distribution[0],
            distribution[1],
            distribution[2],
            distribution[3],
            distribution[4]
        );
    }
}
