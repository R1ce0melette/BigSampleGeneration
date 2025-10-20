// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title JobBoard
 * @dev A contract for a job board where employers can post jobs and workers can apply
 */
contract JobBoard {
    enum JobStatus { OPEN, CLOSED, FILLED }
    
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 payment;
        JobStatus status;
        uint256 postedAt;
        address[] applicants;
        address selectedWorker;
    }
    
    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => mapping(address => bool)) public hasApplied;
    
    // Events
    event JobPosted(uint256 indexed jobId, address indexed employer, string title, uint256 payment);
    event JobApplicationSubmitted(uint256 indexed jobId, address indexed worker);
    event WorkerSelected(uint256 indexed jobId, address indexed worker);
    event JobClosed(uint256 indexed jobId);
    event PaymentReleased(uint256 indexed jobId, address indexed worker, uint256 amount);
    
    /**
     * @dev Post a new job
     * @param title The job title
     * @param description The job description
     */
    function postJob(string memory title, string memory description) external payable {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(msg.value > 0, "Payment must be greater than 0");
        
        jobCount++;
        
        Job storage newJob = jobs[jobCount];
        newJob.id = jobCount;
        newJob.employer = msg.sender;
        newJob.title = title;
        newJob.description = description;
        newJob.payment = msg.value;
        newJob.status = JobStatus.OPEN;
        newJob.postedAt = block.timestamp;
        
        emit JobPosted(jobCount, msg.sender, title, msg.value);
    }
    
    /**
     * @dev Apply for a job
     * @param jobId The ID of the job to apply for
     */
    function applyForJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[jobId];
        
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(msg.sender != job.employer, "Employer cannot apply to their own job");
        require(!hasApplied[jobId][msg.sender], "Already applied to this job");
        
        job.applicants.push(msg.sender);
        hasApplied[jobId][msg.sender] = true;
        
        emit JobApplicationSubmitted(jobId, msg.sender);
    }
    
    /**
     * @dev Select a worker for the job and release payment
     * @param jobId The ID of the job
     * @param worker The address of the selected worker
     */
    function selectWorker(uint256 jobId, address worker) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[jobId];
        
        require(msg.sender == job.employer, "Only employer can select worker");
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(hasApplied[jobId][worker], "Worker has not applied for this job");
        
        job.selectedWorker = worker;
        job.status = JobStatus.FILLED;
        
        // Release payment to selected worker
        (bool success, ) = worker.call{value: job.payment}("");
        require(success, "Payment transfer failed");
        
        emit WorkerSelected(jobId, worker);
        emit PaymentReleased(jobId, worker, job.payment);
    }
    
    /**
     * @dev Close a job without selecting a worker (refunds employer)
     * @param jobId The ID of the job
     */
    function closeJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[jobId];
        
        require(msg.sender == job.employer, "Only employer can close job");
        require(job.status == JobStatus.OPEN, "Job is not open");
        
        job.status = JobStatus.CLOSED;
        
        // Refund payment to employer
        (bool success, ) = job.employer.call{value: job.payment}("");
        require(success, "Refund transfer failed");
        
        emit JobClosed(jobId);
    }
    
    /**
     * @dev Get job details
     * @param jobId The ID of the job
     * @return id Job ID
     * @return employer Employer's address
     * @return title Job title
     * @return description Job description
     * @return payment Payment amount
     * @return status Job status
     * @return postedAt Timestamp when posted
     * @return applicantCount Number of applicants
     * @return selectedWorker Selected worker address (if any)
     */
    function getJob(uint256 jobId) external view returns (
        uint256 id,
        address employer,
        string memory title,
        string memory description,
        uint256 payment,
        JobStatus status,
        uint256 postedAt,
        uint256 applicantCount,
        address selectedWorker
    ) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        Job memory job = jobs[jobId];
        
        return (
            job.id,
            job.employer,
            job.title,
            job.description,
            job.payment,
            job.status,
            job.postedAt,
            job.applicants.length,
            job.selectedWorker
        );
    }
    
    /**
     * @dev Get all applicants for a job
     * @param jobId The ID of the job
     * @return Array of applicant addresses
     */
    function getJobApplicants(uint256 jobId) external view returns (address[] memory) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        return jobs[jobId].applicants;
    }
    
    /**
     * @dev Get all open jobs
     * @return Array of open job IDs
     */
    function getOpenJobs() external view returns (uint256[] memory) {
        uint256 openCount = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                openCount++;
            }
        }
        
        uint256[] memory openJobs = new uint256[](openCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                openJobs[index] = i;
                index++;
            }
        }
        
        return openJobs;
    }
    
    /**
     * @dev Get all jobs posted by an employer
     * @param employer The employer's address
     * @return Array of job IDs
     */
    function getJobsByEmployer(address employer) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == employer) {
                count++;
            }
        }
        
        uint256[] memory employerJobs = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == employer) {
                employerJobs[index] = i;
                index++;
            }
        }
        
        return employerJobs;
    }
    
    /**
     * @dev Get all jobs a worker has applied to
     * @param worker The worker's address
     * @return Array of job IDs
     */
    function getJobsAppliedByWorker(address worker) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][worker]) {
                count++;
            }
        }
        
        uint256[] memory appliedJobs = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][worker]) {
                appliedJobs[index] = i;
                index++;
            }
        }
        
        return appliedJobs;
    }
    
    /**
     * @dev Get all jobs won by a worker
     * @param worker The worker's address
     * @return Array of job IDs where worker was selected
     */
    function getJobsWonByWorker(address worker) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].selectedWorker == worker) {
                count++;
            }
        }
        
        uint256[] memory wonJobs = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].selectedWorker == worker) {
                wonJobs[index] = i;
                index++;
            }
        }
        
        return wonJobs;
    }
    
    /**
     * @dev Check if a worker has applied to a specific job
     * @param jobId The job ID
     * @param worker The worker's address
     * @return True if worker has applied, false otherwise
     */
    function hasWorkerApplied(uint256 jobId, address worker) external view returns (bool) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        return hasApplied[jobId][worker];
    }
    
    /**
     * @dev Get the caller's posted jobs
     * @return Array of job IDs posted by the caller
     */
    function getMyPostedJobs() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == msg.sender) {
                count++;
            }
        }
        
        uint256[] memory myJobs = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == msg.sender) {
                myJobs[index] = i;
                index++;
            }
        }
        
        return myJobs;
    }
    
    /**
     * @dev Get the caller's applications
     * @return Array of job IDs the caller has applied to
     */
    function getMyApplications() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][msg.sender]) {
                count++;
            }
        }
        
        uint256[] memory myApplications = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= jobCount; i++) {
            if (hasApplied[i][msg.sender]) {
                myApplications[index] = i;
                index++;
            }
        }
        
        return myApplications;
    }
    
    /**
     * @dev Get platform statistics
     * @return totalJobs Total number of jobs posted
     * @return openJobs Number of open jobs
     * @return filledJobs Number of filled jobs
     * @return closedJobs Number of closed jobs
     */
    function getStats() external view returns (
        uint256 totalJobs,
        uint256 openJobs,
        uint256 filledJobs,
        uint256 closedJobs
    ) {
        uint256 open = 0;
        uint256 filled = 0;
        uint256 closed = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                open++;
            } else if (jobs[i].status == JobStatus.FILLED) {
                filled++;
            } else if (jobs[i].status == JobStatus.CLOSED) {
                closed++;
            }
        }
        
        return (jobCount, open, filled, closed);
    }
}
