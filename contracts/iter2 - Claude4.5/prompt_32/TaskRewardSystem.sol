// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskRewardSystem {
    address public owner;
    
    enum TaskStatus { OPEN, ASSIGNED, COMPLETED, VERIFIED, CANCELLED }
    
    struct Task {
        uint256 taskId;
        string title;
        string description;
        uint256 reward;
        address assignedTo;
        TaskStatus status;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userAssignedTasks;
    mapping(address => uint256[]) public userCompletedTasks;
    mapping(address => uint256) public userTotalEarned;
    
    uint256 public totalRewardsDistributed;
    
    event TaskCreated(uint256 indexed taskId, string title, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed user);
    event TaskCompleted(uint256 indexed taskId, address indexed user);
    event TaskVerified(uint256 indexed taskId, address indexed user, uint256 reward);
    event TaskCancelled(uint256 indexed taskId);
    event FundsDeposited(address indexed from, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward
    ) external onlyOwner returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_reward > 0, "Reward must be greater than 0");
        require(address(this).balance >= _reward, "Insufficient contract balance for reward");
        
        taskCount++;
        
        tasks[taskCount] = Task({
            taskId: taskCount,
            title: _title,
            description: _description,
            reward: _reward,
            assignedTo: address(0),
            status: TaskStatus.OPEN,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        emit TaskCreated(taskCount, _title, _reward);
        
        return taskCount;
    }
    
    function assignTask(uint256 _taskId, address _user) external onlyOwner taskExists(_taskId) {
        require(_user != address(0), "User address cannot be zero");
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OPEN, "Task is not open");
        
        task.assignedTo = _user;
        task.status = TaskStatus.ASSIGNED;
        
        userAssignedTasks[_user].push(_taskId);
        
        emit TaskAssigned(_taskId, _user);
    }
    
    function selfAssignTask(uint256 _taskId) external taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OPEN, "Task is not open");
        
        task.assignedTo = msg.sender;
        task.status = TaskStatus.ASSIGNED;
        
        userAssignedTasks[msg.sender].push(_taskId);
        
        emit TaskAssigned(_taskId, msg.sender);
    }
    
    function completeTask(uint256 _taskId) external taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ASSIGNED, "Task is not assigned");
        require(task.assignedTo == msg.sender, "You are not assigned to this task");
        
        task.status = TaskStatus.COMPLETED;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(_taskId, msg.sender);
    }
    
    function verifyAndReward(uint256 _taskId) external onlyOwner taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.COMPLETED, "Task is not completed");
        require(address(this).balance >= task.reward, "Insufficient contract balance");
        
        task.status = TaskStatus.VERIFIED;
        
        address user = task.assignedTo;
        uint256 reward = task.reward;
        
        userCompletedTasks[user].push(_taskId);
        userTotalEarned[user] += reward;
        totalRewardsDistributed += reward;
        
        (bool success, ) = payable(user).call{value: reward}("");
        require(success, "Reward transfer failed");
        
        emit TaskVerified(_taskId, user, reward);
    }
    
    function cancelTask(uint256 _taskId) external onlyOwner taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OPEN || task.status == TaskStatus.ASSIGNED, "Cannot cancel task in current status");
        
        task.status = TaskStatus.CANCELLED;
        
        emit TaskCancelled(_taskId);
    }
    
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function getTask(uint256 _taskId) external view taskExists(_taskId) returns (
        string memory title,
        string memory description,
        uint256 reward,
        address assignedTo,
        TaskStatus status,
        uint256 createdAt,
        uint256 completedAt
    ) {
        Task memory task = tasks[_taskId];
        
        return (
            task.title,
            task.description,
            task.reward,
            task.assignedTo,
            task.status,
            task.createdAt,
            task.completedAt
        );
    }
    
    function getUserAssignedTasks(address _user) external view returns (uint256[] memory) {
        return userAssignedTasks[_user];
    }
    
    function getUserCompletedTasks(address _user) external view returns (uint256[] memory) {
        return userCompletedTasks[_user];
    }
    
    function getUserTotalEarned(address _user) external view returns (uint256) {
        return userTotalEarned[_user];
    }
    
    function getOpenTasks() external view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openCount++;
            }
        }
        
        uint256[] memory openTasks = new uint256[](openCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openTasks[index] = i;
                index++;
            }
        }
        
        return openTasks;
    }
    
    function getMyAssignedTasks() external view returns (uint256[] memory) {
        return userAssignedTasks[msg.sender];
    }
    
    function getMyCompletedTasks() external view returns (uint256[] memory) {
        return userCompletedTasks[msg.sender];
    }
    
    function getMyTotalEarned() external view returns (uint256) {
        return userTotalEarned[msg.sender];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getTotalRewardsDistributed() external view returns (uint256) {
        return totalRewardsDistributed;
    }
    
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
    
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
