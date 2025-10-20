// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title JobBoard
 * @dev A job board contract where employers can post jobs and workers can apply by submitting their address
 */
contract JobBoard {
    // Job structure
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 payment;
        bool isActive;
        bool isCompleted;
        address selectedWorker;
        uint256 createdAt;
        uint256 applicantCount;
    }
    
    // State variables
    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => address[]) public jobApplicants;
    mapping(uint256 => mapping(address => bool)) public hasApplied;
    
    // Events
    event JobPosted(uint256 indexed jobId, address indexed employer, string title, uint256 payment, uint256 timestamp);
    event JobApplicationSubmitted(uint256 indexed jobId, address indexed applicant, uint256 timestamp);
    event WorkerSelected(uint256 indexed jobId, address indexed worker, address indexed employer);
    event JobCompleted(uint256 indexed jobId, address indexed worker, uint256 payment);
    event JobCancelled(uint256 indexed jobId, address indexed employer);
    event PaymentDeposited(uint256 indexed jobId, uint256 amount);
    
    /**
     * @dev Post a new job
     * @param title The job title
     * @param description The job description
     * @return jobId The ID of the posted job
     */
    function postJob(string memory title, string memory description) external payable returns (uint256) {
        require(bytes(title).length > 0, "Job title cannot be empty");
        require(bytes(description).length > 0, "Job description cannot be empty");
        require(msg.value > 0, "Payment must be greater than 0");
        
        jobCount++;
        uint256 jobId = jobCount;
        
        jobs[jobId] = Job({
            id: jobId,
            employer: msg.sender,
            title: title,
            description: description,
            payment: msg.value,
            isActive: true,
            isCompleted: false,
            selectedWorker: address(0),
            createdAt: block.timestamp,
            applicantCount: 0
        });
        
        emit JobPosted(jobId, msg.sender, title, msg.value, block.timestamp);
        emit PaymentDeposited(jobId, msg.value);
        
        return jobId;
    }
    
    /**
     * @dev Apply for a job
     * @param jobId The ID of the job to apply for
     */
    function applyForJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[jobId];
        
        require(job.isActive, "Job is not active");
        require(!job.isCompleted, "Job is already completed");
        require(job.selectedWorker == address(0), "Worker already selected");
        require(msg.sender != job.employer, "Employer cannot apply to their own job");
        require(!hasApplied[jobId][msg.sender], "Already applied to this job");
        
        jobApplicants[jobId].push(msg.sender);
        hasApplied[jobId][msg.sender] = true;
        jobs[jobId].applicantCount++;
        
        emit JobApplicationSubmitted(jobId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Select a worker for the job
     * @param jobId The ID of the job
     * @param worker The address of the selected worker
     */
    function selectWorker(uint256 jobId, address worker) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[jobId];
        
        require(msg.sender == job.employer, "Only employer can select worker");
        require(job.isActive, "Job is not active");
        require(!job.isCompleted, "Job is already completed");
        require(job.selectedWorker == address(0), "Worker already selected");
        require(hasApplied[jobId][worker], "Worker has not applied to this job");
        
        job.selectedWorker = worker;
        
        emit WorkerSelected(jobId, worker, msg.sender);
    }
    
    /**
     * @dev Mark job as completed and release payment to worker
     * @param jobId The ID of the job
     */
    function completeJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[jobId];
        
        require(msg.sender == job.employer, "Only employer can complete job");
        require(job.isActive, "Job is not active");
        require(!job.isCompleted, "Job is already completed");
        require(job.selectedWorker != address(0), "No worker selected");
        
        job.isCompleted = true;
        job.isActive = false;
        
        uint256 payment = job.payment;
        
        (bool success, ) = job.selectedWorker.call{value: payment}("");
        require(success, "Payment transfer failed");
        
        emit JobCompleted(jobId, job.selectedWorker, payment);
    }
    
    /**
     * @dev Cancel a job and refund employer
     * @param jobId The ID of the job
     */
    function cancelJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[jobId];
        
        require(msg.sender == job.employer, "Only employer can cancel job");
        require(job.isActive, "Job is not active");
        require(!job.isCompleted, "Cannot cancel completed job");
        require(job.selectedWorker == address(0), "Cannot cancel job with selected worker");
        
        job.isActive = false;
        
        uint256 refund = job.payment;
        job.payment = 0;
        
        (bool success, ) = job.employer.call{value: refund}("");
        require(success, "Refund transfer failed");
        
        emit JobCancelled(jobId, msg.sender);
    }
    
    /**
     * @dev Get job details
     * @param jobId The ID of the job
     * @return id Job ID
     * @return employer Employer's address
     * @return title Job title
     * @return description Job description
     * @return payment Payment amount
     * @return isActive Whether job is active
     * @return isCompleted Whether job is completed
     * @return selectedWorker Selected worker's address
     * @return createdAt Creation timestamp
     * @return applicantCount Number of applicants
     */
    function getJob(uint256 jobId) external view returns (
        uint256 id,
        address employer,
        string memory title,
        string memory description,
        uint256 payment,
        bool isActive,
        bool isCompleted,
        address selectedWorker,
        uint256 createdAt,
        uint256 applicantCount
    ) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        
        Job memory job = jobs[jobId];
        return (
            job.id,
            job.employer,
            job.title,
            job.description,
            job.payment,
            job.isActive,
            job.isCompleted,
            job.selectedWorker,
            job.createdAt,
            job.applicantCount
        );
    }
    
    /**
     * @dev Get all applicants for a job
     * @param jobId The ID of the job
     * @return Array of applicant addresses
     */
    function getJobApplicants(uint256 jobId) external view returns (address[] memory) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        return jobApplicants[jobId];
    }
    
    /**
     * @dev Get all active jobs
     * @return Array of active job IDs
     */
    function getActiveJobs() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active jobs
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].isActive && !jobs[i].isCompleted) {
                activeCount++;
            }
        }
        
        // Create array
        uint256[] memory activeJobIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].isActive && !jobs[i].isCompleted) {
                activeJobIds[index] = i;
                index++;
            }
        }
        
        return activeJobIds;
    }
    
    /**
     * @dev Get jobs posted by an employer
     * @param employer The employer's address
     * @return Array of job IDs
     */
    function getEmployerJobs(address employer) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count jobs
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == employer) {
                count++;
            }
        }
        
        // Create array
        uint256[] memory employerJobIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == employer) {
                employerJobIds[index] = i;
                index++;
            }
        }
        
        return employerJobIds;
    }
    
    /**
     * @dev Get jobs a worker has applied to
     * @param worker The worker's address
     * @return Array of job IDs
     */
    function getWorkerApplications(address worker) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count applications
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][worker]) {
                count++;
            }
        }
        
        // Create array
        uint256[] memory applicationIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][worker]) {
                applicationIds[index] = i;
                index++;
            }
        }
        
        return applicationIds;
    }
    
    /**
     * @dev Get jobs where caller is the employer
     * @return Array of job IDs
     */
    function getMyPostedJobs() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == msg.sender) {
                count++;
            }
        }
        
        uint256[] memory myJobIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == msg.sender) {
                myJobIds[index] = i;
                index++;
            }
        }
        
        return myJobIds;
    }
    
    /**
     * @dev Get jobs caller has applied to
     * @return Array of job IDs
     */
    function getMyApplications() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][msg.sender]) {
                count++;
            }
        }
        
        uint256[] memory myApplicationIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][msg.sender]) {
                myApplicationIds[index] = i;
                index++;
            }
        }
        
        return myApplicationIds;
    }
    
    /**
     * @dev Check if an address has applied to a job
     * @param jobId The ID of the job
     * @param worker The worker's address
     * @return True if the worker has applied, false otherwise
     */
    function hasWorkerApplied(uint256 jobId, address worker) external view returns (bool) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        return hasApplied[jobId][worker];
    }
}
