// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FeedbackSystem
 * @dev Contract that records user feedback and ratings from 1 to 5 stars
 */
contract FeedbackSystem {
    // Feedback structure
    struct Feedback {
        address user;
        uint8 rating;
        string comment;
        uint256 timestamp;
        uint256 id;
    }

    // Rating statistics
    struct RatingStats {
        uint256 totalRatings;
        uint256 sumRatings;
        uint256 oneStarCount;
        uint256 twoStarCount;
        uint256 threeStarCount;
        uint256 fourStarCount;
        uint256 fiveStarCount;
    }

    // State variables
    address public owner;
    uint256 private feedbackCounter;
    
    mapping(uint256 => Feedback) private feedbacks;
    mapping(address => uint256[]) private userFeedbackIds;
    mapping(address => bool) private hasSubmittedFeedback;
    
    uint256[] private allFeedbackIds;
    RatingStats private stats;

    // Events
    event FeedbackSubmitted(address indexed user, uint256 indexed feedbackId, uint8 rating, uint256 timestamp);
    event FeedbackUpdated(address indexed user, uint256 indexed feedbackId, uint8 oldRating, uint8 newRating);
    event FeedbackDeleted(address indexed user, uint256 indexed feedbackId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier validRating(uint8 rating) {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        _;
    }

    modifier feedbackExists(uint256 feedbackId) {
        require(feedbacks[feedbackId].user != address(0), "Feedback does not exist");
        _;
    }

    modifier onlyFeedbackOwner(uint256 feedbackId) {
        require(feedbacks[feedbackId].user == msg.sender, "Not the feedback owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        feedbackCounter = 0;
    }

    /**
     * @dev Submit feedback with rating and comment
     * @param rating Rating from 1 to 5
     * @param comment Feedback comment
     * @return feedbackId ID of the submitted feedback
     */
    function submitFeedback(uint8 rating, string memory comment) 
        public 
        validRating(rating) 
        returns (uint256) 
    {
        feedbackCounter++;
        uint256 feedbackId = feedbackCounter;

        Feedback memory newFeedback = Feedback({
            user: msg.sender,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp,
            id: feedbackId
        });

        feedbacks[feedbackId] = newFeedback;
        userFeedbackIds[msg.sender].push(feedbackId);
        allFeedbackIds.push(feedbackId);
        
        if (!hasSubmittedFeedback[msg.sender]) {
            hasSubmittedFeedback[msg.sender] = true;
        }

        // Update statistics
        stats.totalRatings++;
        stats.sumRatings += rating;
        _incrementRatingCount(rating);

        emit FeedbackSubmitted(msg.sender, feedbackId, rating, block.timestamp);

        return feedbackId;
    }

    /**
     * @dev Submit feedback with rating only
     * @param rating Rating from 1 to 5
     * @return feedbackId ID of the submitted feedback
     */
    function submitRating(uint8 rating) public validRating(rating) returns (uint256) {
        return submitFeedback(rating, "");
    }

    /**
     * @dev Update existing feedback
     * @param feedbackId ID of the feedback to update
     * @param rating New rating
     * @param comment New comment
     */
    function updateFeedback(uint256 feedbackId, uint8 rating, string memory comment) 
        public 
        feedbackExists(feedbackId)
        onlyFeedbackOwner(feedbackId)
        validRating(rating)
    {
        Feedback storage feedback = feedbacks[feedbackId];
        uint8 oldRating = feedback.rating;

        // Update statistics
        stats.sumRatings = stats.sumRatings - oldRating + rating;
        _decrementRatingCount(oldRating);
        _incrementRatingCount(rating);

        feedback.rating = rating;
        feedback.comment = comment;
        feedback.timestamp = block.timestamp;

        emit FeedbackUpdated(msg.sender, feedbackId, oldRating, rating);
    }

    /**
     * @dev Delete feedback (only by feedback owner or contract owner)
     * @param feedbackId ID of the feedback to delete
     */
    function deleteFeedback(uint256 feedbackId) 
        public 
        feedbackExists(feedbackId)
    {
        Feedback storage feedback = feedbacks[feedbackId];
        require(
            feedback.user == msg.sender || msg.sender == owner,
            "Not authorized to delete this feedback"
        );

        // Update statistics
        stats.totalRatings--;
        stats.sumRatings -= feedback.rating;
        _decrementRatingCount(feedback.rating);

        emit FeedbackDeleted(feedback.user, feedbackId);

        delete feedbacks[feedbackId];
    }

    /**
     * @dev Get feedback by ID
     * @param feedbackId Feedback ID
     * @return Feedback details
     */
    function getFeedback(uint256 feedbackId) 
        public 
        view 
        feedbackExists(feedbackId) 
        returns (Feedback memory) 
    {
        return feedbacks[feedbackId];
    }

    /**
     * @dev Get all feedback IDs for a user
     * @param user User address
     * @return Array of feedback IDs
     */
    function getUserFeedbackIds(address user) public view returns (uint256[] memory) {
        return userFeedbackIds[user];
    }

    /**
     * @dev Get all feedback submitted by a user
     * @param user User address
     * @return Array of feedbacks
     */
    function getUserFeedbacks(address user) public view returns (Feedback[] memory) {
        uint256[] memory ids = userFeedbackIds[user];
        Feedback[] memory userFeedbacks = new Feedback[](ids.length);

        uint256 count = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            if (feedbacks[ids[i]].user != address(0)) {
                userFeedbacks[count] = feedbacks[ids[i]];
                count++;
            }
        }

        // Resize array to actual count
        Feedback[] memory result = new Feedback[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userFeedbacks[i];
        }

        return result;
    }

    /**
     * @dev Get all feedback IDs
     * @return Array of all feedback IDs
     */
    function getAllFeedbackIds() public view returns (uint256[] memory) {
        return allFeedbackIds;
    }

    /**
     * @dev Get all feedbacks
     * @return Array of all feedbacks
     */
    function getAllFeedbacks() public view returns (Feedback[] memory) {
        Feedback[] memory allFeedbacks = new Feedback[](allFeedbackIds.length);

        uint256 count = 0;
        for (uint256 i = 0; i < allFeedbackIds.length; i++) {
            if (feedbacks[allFeedbackIds[i]].user != address(0)) {
                allFeedbacks[count] = feedbacks[allFeedbackIds[i]];
                count++;
            }
        }

        // Resize array to actual count
        Feedback[] memory result = new Feedback[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = allFeedbacks[i];
        }

        return result;
    }

    /**
     * @dev Get feedbacks by rating
     * @param rating Rating to filter by
     * @return Array of feedbacks with the specified rating
     */
    function getFeedbacksByRating(uint8 rating) 
        public 
        view 
        validRating(rating) 
        returns (Feedback[] memory) 
    {
        uint256 count = _getRatingCount(rating);
        Feedback[] memory result = new Feedback[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < allFeedbackIds.length; i++) {
            Feedback memory fb = feedbacks[allFeedbackIds[i]];
            if (fb.user != address(0) && fb.rating == rating) {
                result[index] = fb;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get recent feedbacks
     * @param count Number of recent feedbacks to retrieve
     * @return Array of recent feedbacks
     */
    function getRecentFeedbacks(uint256 count) public view returns (Feedback[] memory) {
        uint256 totalCount = allFeedbackIds.length;
        uint256 resultCount = count > totalCount ? totalCount : count;

        Feedback[] memory result = new Feedback[](resultCount);
        uint256 index = 0;

        for (uint256 i = totalCount; i > 0 && index < resultCount; i--) {
            if (feedbacks[allFeedbackIds[i - 1]].user != address(0)) {
                result[index] = feedbacks[allFeedbackIds[i - 1]];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get average rating
     * @return Average rating (scaled by 100 for precision)
     */
    function getAverageRating() public view returns (uint256) {
        if (stats.totalRatings == 0) {
            return 0;
        }
        return (stats.sumRatings * 100) / stats.totalRatings;
    }

    /**
     * @dev Get rating statistics
     * @return totalRatings Total number of ratings
     * @return averageRating Average rating (scaled by 100)
     * @return oneStarCount Number of 1-star ratings
     * @return twoStarCount Number of 2-star ratings
     * @return threeStarCount Number of 3-star ratings
     * @return fourStarCount Number of 4-star ratings
     * @return fiveStarCount Number of 5-star ratings
     */
    function getRatingStatistics() 
        public 
        view 
        returns (
            uint256 totalRatings,
            uint256 averageRating,
            uint256 oneStarCount,
            uint256 twoStarCount,
            uint256 threeStarCount,
            uint256 fourStarCount,
            uint256 fiveStarCount
        ) 
    {
        return (
            stats.totalRatings,
            getAverageRating(),
            stats.oneStarCount,
            stats.twoStarCount,
            stats.threeStarCount,
            stats.fourStarCount,
            stats.fiveStarCount
        );
    }

    /**
     * @dev Get rating distribution percentages
     * @return Distribution array [1-star%, 2-star%, 3-star%, 4-star%, 5-star%] (scaled by 100)
     */
    function getRatingDistribution() public view returns (uint256[5] memory) {
        uint256[5] memory distribution;
        
        if (stats.totalRatings == 0) {
            return distribution;
        }

        distribution[0] = (stats.oneStarCount * 10000) / stats.totalRatings;
        distribution[1] = (stats.twoStarCount * 10000) / stats.totalRatings;
        distribution[2] = (stats.threeStarCount * 10000) / stats.totalRatings;
        distribution[3] = (stats.fourStarCount * 10000) / stats.totalRatings;
        distribution[4] = (stats.fiveStarCount * 10000) / stats.totalRatings;

        return distribution;
    }

    /**
     * @dev Check if user has submitted feedback
     * @param user User address
     * @return true if user has submitted feedback
     */
    function hasUserSubmittedFeedback(address user) public view returns (bool) {
        return hasSubmittedFeedback[user];
    }

    /**
     * @dev Get total feedback count
     * @return Total number of feedbacks
     */
    function getTotalFeedbackCount() public view returns (uint256) {
        return stats.totalRatings;
    }

    /**
     * @dev Get user feedback count
     * @param user User address
     * @return Number of feedbacks by user
     */
    function getUserFeedbackCount(address user) public view returns (uint256) {
        uint256 count = 0;
        uint256[] memory ids = userFeedbackIds[user];
        
        for (uint256 i = 0; i < ids.length; i++) {
            if (feedbacks[ids[i]].user != address(0)) {
                count++;
            }
        }
        
        return count;
    }

    /**
     * @dev Get feedbacks in time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of feedbacks in the time range
     */
    function getFeedbacksInTimeRange(uint256 startTime, uint256 endTime) 
        public 
        view 
        returns (Feedback[] memory) 
    {
        require(endTime >= startTime, "Invalid time range");

        uint256 count = 0;
        for (uint256 i = 0; i < allFeedbackIds.length; i++) {
            Feedback memory fb = feedbacks[allFeedbackIds[i]];
            if (fb.user != address(0) && fb.timestamp >= startTime && fb.timestamp <= endTime) {
                count++;
            }
        }

        Feedback[] memory result = new Feedback[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allFeedbackIds.length; i++) {
            Feedback memory fb = feedbacks[allFeedbackIds[i]];
            if (fb.user != address(0) && fb.timestamp >= startTime && fb.timestamp <= endTime) {
                result[index] = fb;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Internal function to increment rating count
     * @param rating Rating value
     */
    function _incrementRatingCount(uint8 rating) private {
        if (rating == 1) stats.oneStarCount++;
        else if (rating == 2) stats.twoStarCount++;
        else if (rating == 3) stats.threeStarCount++;
        else if (rating == 4) stats.fourStarCount++;
        else if (rating == 5) stats.fiveStarCount++;
    }

    /**
     * @dev Internal function to decrement rating count
     * @param rating Rating value
     */
    function _decrementRatingCount(uint8 rating) private {
        if (rating == 1) stats.oneStarCount--;
        else if (rating == 2) stats.twoStarCount--;
        else if (rating == 3) stats.threeStarCount--;
        else if (rating == 4) stats.fourStarCount--;
        else if (rating == 5) stats.fiveStarCount--;
    }

    /**
     * @dev Internal function to get rating count
     * @param rating Rating value
     * @return Count of feedbacks with the rating
     */
    function _getRatingCount(uint8 rating) private view returns (uint256) {
        if (rating == 1) return stats.oneStarCount;
        if (rating == 2) return stats.twoStarCount;
        if (rating == 3) return stats.threeStarCount;
        if (rating == 4) return stats.fourStarCount;
        if (rating == 5) return stats.fiveStarCount;
        return 0;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }
}
