// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 payment;
        bool isOpen;
        bool isCompleted;
        address selectedWorker;
        uint256 createdAt;
    }
    
    struct Application {
        address worker;
        uint256 timestamp;
        string message;
    }
    
    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => Application[]) public jobApplications;
    mapping(uint256 => mapping(address => bool)) public hasApplied;
    
    // Events
    event JobPosted(uint256 indexed jobId, address indexed employer, string title, uint256 payment);
    event JobApplicationSubmitted(uint256 indexed jobId, address indexed worker, string message);
    event WorkerSelected(uint256 indexed jobId, address indexed worker);
    event JobCompleted(uint256 indexed jobId, address indexed worker, uint256 payment);
    event JobCancelled(uint256 indexed jobId);
    
    /**
     * @dev Post a new job
     * @param _title The job title
     * @param _description The job description
     */
    function postJob(string memory _title, string memory _description) external payable {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(msg.value > 0, "Payment must be greater than 0");
        
        jobCount++;
        
        jobs[jobCount] = Job({
            id: jobCount,
            employer: msg.sender,
            title: _title,
            description: _description,
            payment: msg.value,
            isOpen: true,
            isCompleted: false,
            selectedWorker: address(0),
            createdAt: block.timestamp
        });
        
        emit JobPosted(jobCount, msg.sender, _title, msg.value);
    }
    
    /**
     * @dev Apply for a job
     * @param _jobId The ID of the job to apply for
     * @param _message Application message
     */
    function applyForJob(uint256 _jobId, string memory _message) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(job.isOpen, "Job is not open");
        require(msg.sender != job.employer, "Employer cannot apply to own job");
        require(!hasApplied[_jobId][msg.sender], "Already applied to this job");
        
        jobApplications[_jobId].push(Application({
            worker: msg.sender,
            timestamp: block.timestamp,
            message: _message
        }));
        
        hasApplied[_jobId][msg.sender] = true;
        
        emit JobApplicationSubmitted(_jobId, msg.sender, _message);
    }
    
    /**
     * @dev Select a worker for the job
     * @param _jobId The ID of the job
     * @param _worker The address of the selected worker
     */
    function selectWorker(uint256 _jobId, address _worker) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can select worker");
        require(job.isOpen, "Job is not open");
        require(hasApplied[_jobId][_worker], "Worker has not applied");
        
        job.selectedWorker = _worker;
        job.isOpen = false;
        
        emit WorkerSelected(_jobId, _worker);
    }
    
    /**
     * @dev Mark job as completed and release payment
     * @param _jobId The ID of the job
     */
    function completeJob(uint256 _jobId) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can complete job");
        require(!job.isOpen, "Worker not yet selected");
        require(!job.isCompleted, "Job already completed");
        require(job.selectedWorker != address(0), "No worker selected");
        
        job.isCompleted = true;
        
        uint256 payment = job.payment;
        
        (bool success, ) = payable(job.selectedWorker).call{value: payment}("");
        require(success, "Payment transfer failed");
        
        emit JobCompleted(_jobId, job.selectedWorker, payment);
    }
    
    /**
     * @dev Cancel a job and refund employer
     * @param _jobId The ID of the job
     */
    function cancelJob(uint256 _jobId) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can cancel job");
        require(job.isOpen, "Job is not open");
        require(!job.isCompleted, "Job already completed");
        
        job.isOpen = false;
        
        uint256 refundAmount = job.payment;
        
        (bool success, ) = payable(job.employer).call{value: refundAmount}("");
        require(success, "Refund transfer failed");
        
        emit JobCancelled(_jobId);
    }
    
    /**
     * @dev Get job details
     * @param _jobId The ID of the job
     * @return id The job ID
     * @return employer The employer address
     * @return title The job title
     * @return description The job description
     * @return payment The payment amount
     * @return isOpen Whether the job is open
     * @return isCompleted Whether the job is completed
     * @return selectedWorker The selected worker address
     * @return createdAt The creation timestamp
     */
    function getJob(uint256 _jobId) external view returns (
        uint256 id,
        address employer,
        string memory title,
        string memory description,
        uint256 payment,
        bool isOpen,
        bool isCompleted,
        address selectedWorker,
        uint256 createdAt
    ) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job memory job = jobs[_jobId];
        
        return (
            job.id,
            job.employer,
            job.title,
            job.description,
            job.payment,
            job.isOpen,
            job.isCompleted,
            job.selectedWorker,
            job.createdAt
        );
    }
    
    /**
     * @dev Get all applications for a job
     * @param _jobId The ID of the job
     * @return workers Array of worker addresses
     * @return timestamps Array of application timestamps
     * @return messages Array of application messages
     */
    function getJobApplications(uint256 _jobId) external view returns (
        address[] memory workers,
        uint256[] memory timestamps,
        string[] memory messages
    ) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Application[] memory applications = jobApplications[_jobId];
        uint256 count = applications.length;
        
        workers = new address[](count);
        timestamps = new uint256[](count);
        messages = new string[](count);
        
        for (uint256 i = 0; i < count; i++) {
            workers[i] = applications[i].worker;
            timestamps[i] = applications[i].timestamp;
            messages[i] = applications[i].message;
        }
        
        return (workers, timestamps, messages);
    }
    
    /**
     * @dev Get the number of applications for a job
     * @param _jobId The ID of the job
     * @return The number of applications
     */
    function getApplicationCount(uint256 _jobId) external view returns (uint256) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        return jobApplications[_jobId].length;
    }
    
    /**
     * @dev Get open jobs (up to a limit)
     * @param _limit Maximum number of jobs to return
     * @return Array of open job IDs
     */
    function getOpenJobs(uint256 _limit) external view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        // Count open jobs
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].isOpen) {
                openCount++;
            }
        }
        
        uint256 size = openCount < _limit ? openCount : _limit;
        uint256[] memory openJobIds = new uint256[](size);
        
        uint256 index = 0;
        for (uint256 i = jobCount; i >= 1 && index < size; i--) {
            if (jobs[i].isOpen) {
                openJobIds[index] = i;
                index++;
            }
        }
        
        return openJobIds;
    }
    
    /**
     * @dev Check if a worker has applied to a job
     * @param _jobId The ID of the job
     * @param _worker The address of the worker
     * @return True if the worker has applied, false otherwise
     */
    function hasWorkerApplied(uint256 _jobId, address _worker) external view returns (bool) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        return hasApplied[_jobId][_worker];
    }
}
