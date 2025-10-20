// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TaskRewardSystem
 * @dev A contract that implements a simple task reward system where users complete tasks to earn ETH rewards
 */
contract TaskRewardSystem {
    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 reward;
        address assignedTo;
        bool isCompleted;
        bool isApproved;
        bool isActive;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    struct User {
        address userAddress;
        uint256 tasksCompleted;
        uint256 totalEarned;
        bool isRegistered;
    }
    
    address public owner;
    uint256 public totalTasks;
    uint256 public totalRewardsPaid;
    
    mapping(uint256 => Task) public tasks;
    mapping(address => User) public users;
    mapping(address => uint256[]) public userCreatedTasks;
    mapping(address => uint256[]) public userAssignedTasks;
    mapping(address => uint256[]) public userCompletedTasks;
    
    // Events
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed assignedTo);
    event TaskCompleted(uint256 indexed taskId, address indexed completedBy, uint256 timestamp);
    event TaskApproved(uint256 indexed taskId, address indexed approvedBy, uint256 reward);
    event TaskRejected(uint256 indexed taskId, address indexed rejectedBy);
    event RewardClaimed(address indexed user, uint256 amount);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId != 0, "Task does not exist");
        _;
    }
    
    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function");
        _;
    }
    
    modifier onlyAssignedUser(uint256 _taskId) {
        require(tasks[_taskId].assignedTo == msg.sender, "Only assigned user can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Registers a new user
     */
    function registerUser() external {
        require(!users[msg.sender].isRegistered, "User already registered");
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            tasksCompleted: 0,
            totalEarned: 0,
            isRegistered: true
        });
    }
    
    /**
     * @dev Creates a new task with a reward
     * @param _title The title of the task
     * @param _description The description of the task
     * @param _reward The reward amount in wei
     */
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward
    ) external payable returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_reward > 0, "Reward must be greater than 0");
        require(msg.value == _reward, "Must send exact reward amount");
        
        if (!users[msg.sender].isRegistered) {
            users[msg.sender] = User({
                userAddress: msg.sender,
                tasksCompleted: 0,
                totalEarned: 0,
                isRegistered: true
            });
        }
        
        totalTasks++;
        uint256 taskId = totalTasks;
        
        tasks[taskId] = Task({
            taskId: taskId,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            assignedTo: address(0),
            isCompleted: false,
            isApproved: false,
            isActive: true,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        userCreatedTasks[msg.sender].push(taskId);
        
        emit TaskCreated(taskId, msg.sender, _title, _reward);
        
        return taskId;
    }
    
    /**
     * @dev Assigns a task to a user
     * @param _taskId The ID of the task
     * @param _user The address of the user to assign the task to
     */
    function assignTask(uint256 _taskId, address _user) external taskExists(_taskId) onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        
        require(task.isActive, "Task is not active");
        require(task.assignedTo == address(0), "Task already assigned");
        require(_user != address(0), "Invalid user address");
        require(_user != msg.sender, "Cannot assign task to yourself");
        
        task.assignedTo = _user;
        userAssignedTasks[_user].push(_taskId);
        
        emit TaskAssigned(_taskId, _user);
    }
    
    /**
     * @dev Allows a user to claim an unassigned task
     * @param _taskId The ID of the task
     */
    function claimTask(uint256 _taskId) external taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        
        require(task.isActive, "Task is not active");
        require(task.assignedTo == address(0), "Task already assigned");
        require(msg.sender != task.creator, "Cannot claim your own task");
        
        task.assignedTo = msg.sender;
        userAssignedTasks[msg.sender].push(_taskId);
        
        emit TaskAssigned(_taskId, msg.sender);
    }
    
    /**
     * @dev Marks a task as completed by the assigned user
     * @param _taskId The ID of the task
     */
    function completeTask(uint256 _taskId) external taskExists(_taskId) onlyAssignedUser(_taskId) {
        Task storage task = tasks[_taskId];
        
        require(task.isActive, "Task is not active");
        require(!task.isCompleted, "Task already completed");
        
        task.isCompleted = true;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(_taskId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Approves a completed task and releases the reward
     * @param _taskId The ID of the task
     */
    function approveTask(uint256 _taskId) external taskExists(_taskId) onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        
        require(task.isActive, "Task is not active");
        require(task.isCompleted, "Task not completed yet");
        require(!task.isApproved, "Task already approved");
        
        task.isApproved = true;
        task.isActive = false;
        
        // Update user stats
        users[task.assignedTo].tasksCompleted++;
        users[task.assignedTo].totalEarned += task.reward;
        
        userCompletedTasks[task.assignedTo].push(_taskId);
        
        // Transfer reward to the user
        totalRewardsPaid += task.reward;
        payable(task.assignedTo).transfer(task.reward);
        
        emit TaskApproved(_taskId, msg.sender, task.reward);
        emit RewardClaimed(task.assignedTo, task.reward);
    }
    
    /**
     * @dev Rejects a completed task
     * @param _taskId The ID of the task
     */
    function rejectTask(uint256 _taskId) external taskExists(_taskId) onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        
        require(task.isActive, "Task is not active");
        require(task.isCompleted, "Task not completed yet");
        require(!task.isApproved, "Task already approved");
        
        task.isCompleted = false;
        task.completedAt = 0;
        
        emit TaskRejected(_taskId, msg.sender);
    }
    
    /**
     * @dev Cancels a task and refunds the reward to the creator
     * @param _taskId The ID of the task
     */
    function cancelTask(uint256 _taskId) external taskExists(_taskId) onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        
        require(task.isActive, "Task is not active");
        require(!task.isCompleted, "Cannot cancel completed task");
        
        task.isActive = false;
        
        // Refund the reward to the creator
        payable(task.creator).transfer(task.reward);
        
        emit TaskCancelled(_taskId, msg.sender);
    }
    
    /**
     * @dev Returns task details
     * @param _taskId The ID of the task
     * @return taskId The task ID
     * @return creator The creator's address
     * @return title The task title
     * @return description The task description
     * @return reward The reward amount
     * @return assignedTo The assigned user's address
     * @return isCompleted Whether the task is completed
     * @return isApproved Whether the task is approved
     * @return isActive Whether the task is active
     * @return createdAt When the task was created
     * @return completedAt When the task was completed
     */
    function getTask(uint256 _taskId) external view taskExists(_taskId) returns (
        uint256 taskId,
        address creator,
        string memory title,
        string memory description,
        uint256 reward,
        address assignedTo,
        bool isCompleted,
        bool isApproved,
        bool isActive,
        uint256 createdAt,
        uint256 completedAt
    ) {
        Task memory task = tasks[_taskId];
        
        return (
            task.taskId,
            task.creator,
            task.title,
            task.description,
            task.reward,
            task.assignedTo,
            task.isCompleted,
            task.isApproved,
            task.isActive,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Returns user details
     * @param _user The address of the user
     * @return userAddress The user's address
     * @return tasksCompleted Number of tasks completed
     * @return totalEarned Total ETH earned
     * @return isRegistered Whether the user is registered
     */
    function getUser(address _user) external view returns (
        address userAddress,
        uint256 tasksCompleted,
        uint256 totalEarned,
        bool isRegistered
    ) {
        User memory user = users[_user];
        
        return (
            user.userAddress,
            user.tasksCompleted,
            user.totalEarned,
            user.isRegistered
        );
    }
    
    /**
     * @dev Returns all tasks created by a user
     * @param _user The address of the user
     * @return Array of task IDs
     */
    function getUserCreatedTasks(address _user) external view returns (uint256[] memory) {
        return userCreatedTasks[_user];
    }
    
    /**
     * @dev Returns all tasks assigned to a user
     * @param _user The address of the user
     * @return Array of task IDs
     */
    function getUserAssignedTasks(address _user) external view returns (uint256[] memory) {
        return userAssignedTasks[_user];
    }
    
    /**
     * @dev Returns all tasks completed by a user
     * @param _user The address of the user
     * @return Array of task IDs
     */
    function getUserCompletedTasks(address _user) external view returns (uint256[] memory) {
        return userCompletedTasks[_user];
    }
    
    /**
     * @dev Returns all active tasks
     * @return Array of task IDs
     */
    function getActiveTasks() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].isActive) {
                count++;
            }
        }
        
        uint256[] memory activeTasks = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].isActive) {
                activeTasks[index] = i;
                index++;
            }
        }
        
        return activeTasks;
    }
    
    /**
     * @dev Returns all available tasks (active and unassigned)
     * @return Array of task IDs
     */
    function getAvailableTasks() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].isActive && tasks[i].assignedTo == address(0)) {
                count++;
            }
        }
        
        uint256[] memory availableTasks = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].isActive && tasks[i].assignedTo == address(0)) {
                availableTasks[index] = i;
                index++;
            }
        }
        
        return availableTasks;
    }
    
    /**
     * @dev Returns all tasks pending approval
     * @return Array of task IDs
     */
    function getPendingApprovalTasks() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].isActive && tasks[i].isCompleted && !tasks[i].isApproved) {
                count++;
            }
        }
        
        uint256[] memory pendingTasks = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].isActive && tasks[i].isCompleted && !tasks[i].isApproved) {
                pendingTasks[index] = i;
                index++;
            }
        }
        
        return pendingTasks;
    }
    
    /**
     * @dev Returns the total number of tasks
     * @return Total number of tasks
     */
    function getTotalTasks() external view returns (uint256) {
        return totalTasks;
    }
    
    /**
     * @dev Returns the total rewards paid out
     * @return Total rewards paid
     */
    function getTotalRewardsPaid() external view returns (uint256) {
        return totalRewardsPaid;
    }
    
    /**
     * @dev Returns the contract balance
     * @return Contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Checks if a user is registered
     * @param _user The address of the user
     * @return True if registered, false otherwise
     */
    function isUserRegistered(address _user) external view returns (bool) {
        return users[_user].isRegistered;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
