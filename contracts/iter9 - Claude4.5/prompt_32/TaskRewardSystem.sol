// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskRewardSystem {
    address public owner;
    uint256 public taskCounter;
    
    struct Task {
        uint256 id;
        string description;
        uint256 reward;
        address assignedTo;
        bool isCompleted;
        bool exists;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks;
    mapping(address => uint256) public userRewardsEarned;
    
    uint256 public totalTasksCreated;
    uint256 public totalTasksCompleted;
    uint256 public totalRewardsPaid;
    
    // Events
    event TaskCreated(uint256 indexed taskId, string description, uint256 reward, address indexed assignedTo);
    event TaskCompleted(uint256 indexed taskId, address indexed user, uint256 reward);
    event TaskReassigned(uint256 indexed taskId, address indexed oldUser, address indexed newUser);
    event TaskRewardUpdated(uint256 indexed taskId, uint256 oldReward, uint256 newReward);
    event TaskDeleted(uint256 indexed taskId);
    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].exists, "Task does not exist");
        _;
    }
    
    modifier taskNotCompleted(uint256 _taskId) {
        require(!tasks[_taskId].isCompleted, "Task already completed");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Deposit funds to the contract for task rewards
     */
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "Must deposit positive amount");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Receive ETH directly
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Create a new task
     * @param _description Task description
     * @param _reward Reward amount in wei
     * @param _assignedTo Address of user assigned to this task
     */
    function createTask(
        string memory _description,
        uint256 _reward,
        address _assignedTo
    ) external onlyOwner returns (uint256) {
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_reward > 0, "Reward must be greater than 0");
        require(_assignedTo != address(0), "Invalid address");
        
        taskCounter++;
        
        tasks[taskCounter] = Task({
            id: taskCounter,
            description: _description,
            reward: _reward,
            assignedTo: _assignedTo,
            isCompleted: false,
            exists: true,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        userTasks[_assignedTo].push(taskCounter);
        totalTasksCreated++;
        
        emit TaskCreated(taskCounter, _description, _reward, _assignedTo);
        
        return taskCounter;
    }
    
    /**
     * @dev Complete a task and claim reward
     * @param _taskId Task ID to complete
     */
    function completeTask(uint256 _taskId) 
        external 
        taskExists(_taskId) 
        taskNotCompleted(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(msg.sender == task.assignedTo, "Only assigned user can complete this task");
        require(address(this).balance >= task.reward, "Insufficient contract balance");
        
        task.isCompleted = true;
        task.completedAt = block.timestamp;
        
        userRewardsEarned[msg.sender] += task.reward;
        totalTasksCompleted++;
        totalRewardsPaid += task.reward;
        
        // Transfer reward to user
        (bool success, ) = msg.sender.call{value: task.reward}("");
        require(success, "Reward transfer failed");
        
        emit TaskCompleted(_taskId, msg.sender, task.reward);
    }
    
    /**
     * @dev Owner marks a task as completed (manual completion)
     * @param _taskId Task ID to complete
     */
    function manualCompleteTask(uint256 _taskId) 
        external 
        onlyOwner
        taskExists(_taskId) 
        taskNotCompleted(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(address(this).balance >= task.reward, "Insufficient contract balance");
        
        task.isCompleted = true;
        task.completedAt = block.timestamp;
        
        address assignedUser = task.assignedTo;
        userRewardsEarned[assignedUser] += task.reward;
        totalTasksCompleted++;
        totalRewardsPaid += task.reward;
        
        // Transfer reward to assigned user
        (bool success, ) = assignedUser.call{value: task.reward}("");
        require(success, "Reward transfer failed");
        
        emit TaskCompleted(_taskId, assignedUser, task.reward);
    }
    
    /**
     * @dev Reassign a task to a different user
     * @param _taskId Task ID to reassign
     * @param _newUser New user address
     */
    function reassignTask(uint256 _taskId, address _newUser) 
        external 
        onlyOwner 
        taskExists(_taskId) 
        taskNotCompleted(_taskId) 
    {
        require(_newUser != address(0), "Invalid address");
        
        Task storage task = tasks[_taskId];
        address oldUser = task.assignedTo;
        
        task.assignedTo = _newUser;
        userTasks[_newUser].push(_taskId);
        
        emit TaskReassigned(_taskId, oldUser, _newUser);
    }
    
    /**
     * @dev Update task reward amount
     * @param _taskId Task ID
     * @param _newReward New reward amount
     */
    function updateTaskReward(uint256 _taskId, uint256 _newReward) 
        external 
        onlyOwner 
        taskExists(_taskId) 
        taskNotCompleted(_taskId) 
    {
        require(_newReward > 0, "Reward must be greater than 0");
        
        Task storage task = tasks[_taskId];
        uint256 oldReward = task.reward;
        
        task.reward = _newReward;
        
        emit TaskRewardUpdated(_taskId, oldReward, _newReward);
    }
    
    /**
     * @dev Delete a task (only if not completed)
     * @param _taskId Task ID to delete
     */
    function deleteTask(uint256 _taskId) 
        external 
        onlyOwner 
        taskExists(_taskId) 
        taskNotCompleted(_taskId) 
    {
        tasks[_taskId].exists = false;
        
        emit TaskDeleted(_taskId);
    }
    
    /**
     * @dev Get task details
     * @param _taskId Task ID
     */
    function getTask(uint256 _taskId) 
        external 
        view 
        taskExists(_taskId) 
        returns (
            uint256 id,
            string memory description,
            uint256 reward,
            address assignedTo,
            bool isCompleted,
            uint256 createdAt,
            uint256 completedAt
        ) 
    {
        Task memory task = tasks[_taskId];
        return (
            task.id,
            task.description,
            task.reward,
            task.assignedTo,
            task.isCompleted,
            task.createdAt,
            task.completedAt
        );
    }
    
    /**
     * @dev Get all task IDs assigned to a user
     * @param _user User address
     */
    function getUserTasks(address _user) external view returns (uint256[] memory) {
        return userTasks[_user];
    }
    
    /**
     * @dev Get user's active (not completed) tasks
     * @param _user User address
     */
    function getUserActiveTasks(address _user) external view returns (uint256[] memory) {
        uint256[] memory allTasks = userTasks[_user];
        uint256 activeCount = 0;
        
        // Count active tasks
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (tasks[allTasks[i]].exists && !tasks[allTasks[i]].isCompleted) {
                activeCount++;
            }
        }
        
        // Create array of active tasks
        uint256[] memory activeTasks = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (tasks[allTasks[i]].exists && !tasks[allTasks[i]].isCompleted) {
                activeTasks[index] = allTasks[i];
                index++;
            }
        }
        
        return activeTasks;
    }
    
    /**
     * @dev Get user's completed tasks
     * @param _user User address
     */
    function getUserCompletedTasks(address _user) external view returns (uint256[] memory) {
        uint256[] memory allTasks = userTasks[_user];
        uint256 completedCount = 0;
        
        // Count completed tasks
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (tasks[allTasks[i]].exists && tasks[allTasks[i]].isCompleted) {
                completedCount++;
            }
        }
        
        // Create array of completed tasks
        uint256[] memory completedTasks = new uint256[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allTasks.length; i++) {
            if (tasks[allTasks[i]].exists && tasks[allTasks[i]].isCompleted) {
                completedTasks[index] = allTasks[i];
                index++;
            }
        }
        
        return completedTasks;
    }
    
    /**
     * @dev Get total rewards earned by a user
     * @param _user User address
     */
    function getUserRewardsEarned(address _user) external view returns (uint256) {
        return userRewardsEarned[_user];
    }
    
    /**
     * @dev Get contract statistics
     */
    function getStatistics() external view returns (
        uint256 _totalTasksCreated,
        uint256 _totalTasksCompleted,
        uint256 _totalRewardsPaid,
        uint256 _contractBalance
    ) {
        return (
            totalTasksCreated,
            totalTasksCompleted,
            totalRewardsPaid,
            address(this).balance
        );
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Owner withdraws funds from contract
     * @param _amount Amount to withdraw
     */
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(owner, _amount);
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        
        owner = _newOwner;
    }
}
