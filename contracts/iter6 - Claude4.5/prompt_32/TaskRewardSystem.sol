// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TaskRewardSystem
 * @dev A simple task reward system where users complete tasks to earn ETH rewards
 */
contract TaskRewardSystem {
    struct Task {
        uint256 taskId;
        string title;
        string description;
        uint256 reward;
        address creator;
        address assignedTo;
        bool isCompleted;
        bool isVerified;
        bool exists;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    struct UserStats {
        uint256 tasksCompleted;
        uint256 totalEarned;
        uint256 tasksCreated;
    }
    
    address public owner;
    uint256 public taskCount;
    
    mapping(uint256 => Task) public tasks;
    mapping(address => UserStats) public userStats;
    mapping(address => uint256[]) public userCompletedTasks;
    mapping(address => uint256[]) public userCreatedTasks;
    mapping(address => uint256) public pendingRewards;
    
    // Events
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed assignedTo);
    event TaskCompleted(uint256 indexed taskId, address indexed completedBy, uint256 timestamp);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, uint256 reward);
    event TaskRejected(uint256 indexed taskId, address indexed rejector);
    event RewardClaimed(address indexed user, uint256 amount);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event FundsDeposited(address indexed depositor, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier taskExists(uint256 taskId) {
        require(taskId > 0 && taskId <= taskCount, "Task does not exist");
        require(tasks[taskId].exists, "Task does not exist");
        _;
    }
    
    modifier onlyTaskCreator(uint256 taskId) {
        require(tasks[taskId].creator == msg.sender, "Only task creator can perform this action");
        _;
    }
    
    modifier onlyAssignedUser(uint256 taskId) {
        require(tasks[taskId].assignedTo == msg.sender, "Only assigned user can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new task
     * @param title Task title
     * @param description Task description
     * @param reward Reward amount in wei
     */
    function createTask(
        string memory title,
        string memory description,
        uint256 reward
    ) external payable returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(reward > 0, "Reward must be greater than 0");
        require(msg.value >= reward, "Insufficient funds for reward");
        
        taskCount++;
        uint256 taskId = taskCount;
        
        tasks[taskId] = Task({
            taskId: taskId,
            title: title,
            description: description,
            reward: reward,
            creator: msg.sender,
            assignedTo: address(0),
            isCompleted: false,
            isVerified: false,
            exists: true,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        userStats[msg.sender].tasksCreated++;
        userCreatedTasks[msg.sender].push(taskId);
        
        // Refund excess payment
        if (msg.value > reward) {
            uint256 refund = msg.value - reward;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }
        
        emit TaskCreated(taskId, msg.sender, title, reward);
        
        return taskId;
    }
    
    /**
     * @dev Assign a task to a user
     * @param taskId The task ID
     * @param user The user to assign the task to
     */
    function assignTask(uint256 taskId, address user) external taskExists(taskId) onlyTaskCreator(taskId) {
        require(user != address(0), "Invalid user address");
        require(tasks[taskId].assignedTo == address(0), "Task already assigned");
        require(!tasks[taskId].isCompleted, "Task already completed");
        
        tasks[taskId].assignedTo = user;
        
        emit TaskAssigned(taskId, user);
    }
    
    /**
     * @dev Mark a task as completed
     * @param taskId The task ID
     */
    function completeTask(uint256 taskId) external taskExists(taskId) {
        Task storage task = tasks[taskId];
        
        require(!task.isCompleted, "Task already completed");
        require(task.assignedTo == msg.sender || task.assignedTo == address(0), "Not authorized to complete this task");
        
        if (task.assignedTo == address(0)) {
            task.assignedTo = msg.sender;
        }
        
        task.isCompleted = true;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(taskId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Verify and approve task completion
     * @param taskId The task ID
     */
    function verifyTask(uint256 taskId) external taskExists(taskId) onlyTaskCreator(taskId) {
        Task storage task = tasks[taskId];
        
        require(task.isCompleted, "Task not completed yet");
        require(!task.isVerified, "Task already verified");
        require(task.assignedTo != address(0), "Task not assigned");
        
        task.isVerified = true;
        
        // Add reward to user's pending rewards
        pendingRewards[task.assignedTo] += task.reward;
        userStats[task.assignedTo].tasksCompleted++;
        userStats[task.assignedTo].totalEarned += task.reward;
        userCompletedTasks[task.assignedTo].push(taskId);
        
        emit TaskVerified(taskId, msg.sender, task.reward);
    }
    
    /**
     * @dev Reject task completion
     * @param taskId The task ID
     */
    function rejectTask(uint256 taskId) external taskExists(taskId) onlyTaskCreator(taskId) {
        Task storage task = tasks[taskId];
        
        require(task.isCompleted, "Task not completed yet");
        require(!task.isVerified, "Task already verified");
        
        task.isCompleted = false;
        task.completedAt = 0;
        
        emit TaskRejected(taskId, msg.sender);
    }
    
    /**
     * @dev Claim pending rewards
     */
    function claimRewards() external {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        
        pendingRewards[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit RewardClaimed(msg.sender, amount);
    }
    
    /**
     * @dev Cancel a task (only if not completed)
     * @param taskId The task ID
     */
    function cancelTask(uint256 taskId) external taskExists(taskId) onlyTaskCreator(taskId) {
        Task storage task = tasks[taskId];
        
        require(!task.isCompleted, "Cannot cancel completed task");
        require(!task.isVerified, "Cannot cancel verified task");
        
        uint256 refund = task.reward;
        task.exists = false;
        
        // Refund reward to creator
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        require(success, "Refund failed");
        
        emit TaskCancelled(taskId, msg.sender);
    }
    
    /**
     * @dev Get task details
     * @param taskId The task ID
     * @return title Task title
     * @return description Task description
     * @return reward Reward amount
     * @return creator Creator address
     * @return assignedTo Assigned user address
     * @return isCompleted Completion status
     * @return isVerified Verification status
     * @return createdAt Creation timestamp
     */
    function getTask(uint256 taskId) external view taskExists(taskId) returns (
        string memory title,
        string memory description,
        uint256 reward,
        address creator,
        address assignedTo,
        bool isCompleted,
        bool isVerified,
        uint256 createdAt
    ) {
        Task memory task = tasks[taskId];
        
        return (
            task.title,
            task.description,
            task.reward,
            task.creator,
            task.assignedTo,
            task.isCompleted,
            task.isVerified,
            task.createdAt
        );
    }
    
    /**
     * @dev Get user statistics
     * @param user The user address
     * @return tasksCompleted Number of tasks completed
     * @return totalEarned Total ETH earned
     * @return tasksCreated Number of tasks created
     * @return pendingReward Pending reward amount
     */
    function getUserStats(address user) external view returns (
        uint256 tasksCompleted,
        uint256 totalEarned,
        uint256 tasksCreated,
        uint256 pendingReward
    ) {
        UserStats memory stats = userStats[user];
        
        return (
            stats.tasksCompleted,
            stats.totalEarned,
            stats.tasksCreated,
            pendingRewards[user]
        );
    }
    
    /**
     * @dev Get all tasks created by a user
     * @param user The user address
     * @return Array of task IDs
     */
    function getUserCreatedTasks(address user) external view returns (uint256[] memory) {
        return userCreatedTasks[user];
    }
    
    /**
     * @dev Get all tasks completed by a user
     * @param user The user address
     * @return Array of task IDs
     */
    function getUserCompletedTasks(address user) external view returns (uint256[] memory) {
        return userCompletedTasks[user];
    }
    
    /**
     * @dev Get all available tasks (not assigned or not completed)
     * @return Array of task IDs
     */
    function getAvailableTasks() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count available tasks
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && !tasks[i].isCompleted && tasks[i].assignedTo == address(0)) {
                count++;
            }
        }
        
        // Collect task IDs
        uint256[] memory availableTasks = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && !tasks[i].isCompleted && tasks[i].assignedTo == address(0)) {
                availableTasks[index] = i;
                index++;
            }
        }
        
        return availableTasks;
    }
    
    /**
     * @dev Get pending tasks (assigned but not completed)
     * @return Array of task IDs
     */
    function getPendingTasks() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count pending tasks
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && !tasks[i].isCompleted && tasks[i].assignedTo != address(0)) {
                count++;
            }
        }
        
        // Collect task IDs
        uint256[] memory pendingTasks = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && !tasks[i].isCompleted && tasks[i].assignedTo != address(0)) {
                pendingTasks[index] = i;
                index++;
            }
        }
        
        return pendingTasks;
    }
    
    /**
     * @dev Get tasks awaiting verification
     * @return Array of task IDs
     */
    function getTasksAwaitingVerification() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count tasks awaiting verification
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && tasks[i].isCompleted && !tasks[i].isVerified) {
                count++;
            }
        }
        
        // Collect task IDs
        uint256[] memory awaitingTasks = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && tasks[i].isCompleted && !tasks[i].isVerified) {
                awaitingTasks[index] = i;
                index++;
            }
        }
        
        return awaitingTasks;
    }
    
    /**
     * @dev Get user's pending rewards
     * @param user The user address
     * @return Pending reward amount
     */
    function getPendingRewards(address user) external view returns (uint256) {
        return pendingRewards[user];
    }
    
    /**
     * @dev Get total tasks count
     * @return Total number of tasks
     */
    function getTotalTasks() external view returns (uint256) {
        return taskCount;
    }
    
    /**
     * @dev Get contract balance
     * @return Contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Deposit funds to the contract
     */
    function depositFunds() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Transfer ownership
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
