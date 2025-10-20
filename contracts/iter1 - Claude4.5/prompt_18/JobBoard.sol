// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title JobBoard
 * @dev A job board where employers can post jobs and workers can apply by submitting their address
 */
contract JobBoard {
    enum JobStatus {
        OPEN,
        CLOSED,
        FILLED
    }
    
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 salary;
        uint256 postedAt;
        JobStatus status;
        address[] applicants;
        address selectedApplicant;
    }
    
    uint256 private jobCounter;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => mapping(address => bool)) public hasApplied;
    
    mapping(address => uint256[]) private employerJobs;
    mapping(address => uint256[]) private workerApplications;
    
    event JobPosted(
        uint256 indexed jobId,
        address indexed employer,
        string title,
        uint256 salary
    );
    
    event JobApplicationSubmitted(
        uint256 indexed jobId,
        address indexed applicant
    );
    
    event ApplicantSelected(
        uint256 indexed jobId,
        address indexed applicant
    );
    
    event JobClosed(uint256 indexed jobId);
    event JobUpdated(uint256 indexed jobId);
    
    /**
     * @dev Post a new job
     * @param title Job title
     * @param description Job description
     * @param salary Salary offered
     * @return jobId The ID of the posted job
     */
    function postJob(
        string memory title,
        string memory description,
        uint256 salary
    ) external returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(salary > 0, "Salary must be greater than 0");
        
        jobCounter++;
        uint256 jobId = jobCounter;
        
        Job storage newJob = jobs[jobId];
        newJob.id = jobId;
        newJob.employer = msg.sender;
        newJob.title = title;
        newJob.description = description;
        newJob.salary = salary;
        newJob.postedAt = block.timestamp;
        newJob.status = JobStatus.OPEN;
        
        employerJobs[msg.sender].push(jobId);
        
        emit JobPosted(jobId, msg.sender, title, salary);
        
        return jobId;
    }
    
    /**
     * @dev Apply for a job
     * @param jobId The ID of the job to apply for
     */
    function applyForJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        
        require(job.id != 0, "Job does not exist");
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(msg.sender != job.employer, "Employer cannot apply to own job");
        require(!hasApplied[jobId][msg.sender], "Already applied to this job");
        
        job.applicants.push(msg.sender);
        hasApplied[jobId][msg.sender] = true;
        workerApplications[msg.sender].push(jobId);
        
        emit JobApplicationSubmitted(jobId, msg.sender);
    }
    
    /**
     * @dev Select an applicant for the job
     * @param jobId The ID of the job
     * @param applicant The address of the selected applicant
     */
    function selectApplicant(uint256 jobId, address applicant) external {
        Job storage job = jobs[jobId];
        
        require(job.id != 0, "Job does not exist");
        require(msg.sender == job.employer, "Only employer can select applicant");
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(hasApplied[jobId][applicant], "Address has not applied");
        
        job.selectedApplicant = applicant;
        job.status = JobStatus.FILLED;
        
        emit ApplicantSelected(jobId, applicant);
    }
    
    /**
     * @dev Close a job posting
     * @param jobId The ID of the job to close
     */
    function closeJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        
        require(job.id != 0, "Job does not exist");
        require(msg.sender == job.employer, "Only employer can close job");
        require(job.status == JobStatus.OPEN, "Job is not open");
        
        job.status = JobStatus.CLOSED;
        
        emit JobClosed(jobId);
    }
    
    /**
     * @dev Update job details
     * @param jobId The ID of the job
     * @param title New title
     * @param description New description
     * @param salary New salary
     */
    function updateJob(
        uint256 jobId,
        string memory title,
        string memory description,
        uint256 salary
    ) external {
        Job storage job = jobs[jobId];
        
        require(job.id != 0, "Job does not exist");
        require(msg.sender == job.employer, "Only employer can update job");
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(salary > 0, "Salary must be greater than 0");
        
        job.title = title;
        job.description = description;
        job.salary = salary;
        
        emit JobUpdated(jobId);
    }
    
    /**
     * @dev Get job details
     * @param jobId The ID of the job
     * @return id Job ID
     * @return employer Employer address
     * @return title Job title
     * @return description Job description
     * @return salary Salary offered
     * @return postedAt When the job was posted
     * @return status Current status
     * @return applicantCount Number of applicants
     * @return selectedApplicant Selected applicant (if any)
     */
    function getJobDetails(uint256 jobId) external view returns (
        uint256 id,
        address employer,
        string memory title,
        string memory description,
        uint256 salary,
        uint256 postedAt,
        JobStatus status,
        uint256 applicantCount,
        address selectedApplicant
    ) {
        Job storage job = jobs[jobId];
        require(job.id != 0, "Job does not exist");
        
        return (
            job.id,
            job.employer,
            job.title,
            job.description,
            job.salary,
            job.postedAt,
            job.status,
            job.applicants.length,
            job.selectedApplicant
        );
    }
    
    /**
     * @dev Get all applicants for a job
     * @param jobId The ID of the job
     * @return Array of applicant addresses
     */
    function getJobApplicants(uint256 jobId) external view returns (address[] memory) {
        require(jobs[jobId].id != 0, "Job does not exist");
        return jobs[jobId].applicants;
    }
    
    /**
     * @dev Get all jobs posted by an employer
     * @param employer The employer's address
     * @return Array of job IDs
     */
    function getJobsByEmployer(address employer) external view returns (uint256[] memory) {
        return employerJobs[employer];
    }
    
    /**
     * @dev Get all job applications by a worker
     * @param worker The worker's address
     * @return Array of job IDs
     */
    function getApplicationsByWorker(address worker) external view returns (uint256[] memory) {
        return workerApplications[worker];
    }
    
    /**
     * @dev Get all open jobs
     * @return Array of open job IDs
     */
    function getOpenJobs() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count open jobs
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory openJobIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                openJobIds[index] = i;
                index++;
            }
        }
        
        return openJobIds;
    }
    
    /**
     * @dev Get all filled jobs
     * @return Array of filled job IDs
     */
    function getFilledJobs() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count filled jobs
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].status == JobStatus.FILLED) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory filledJobIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].status == JobStatus.FILLED) {
                filledJobIds[index] = i;
                index++;
            }
        }
        
        return filledJobIds;
    }
    
    /**
     * @dev Search jobs by minimum salary
     * @param minSalary Minimum salary filter
     * @return Array of job IDs matching criteria
     */
    function searchJobsBySalary(uint256 minSalary) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count matching jobs
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].status == JobStatus.OPEN && jobs[i].salary >= minSalary) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory matchingJobs = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].status == JobStatus.OPEN && jobs[i].salary >= minSalary) {
                matchingJobs[index] = i;
                index++;
            }
        }
        
        return matchingJobs;
    }
    
    /**
     * @dev Get total number of jobs posted
     * @return The total count
     */
    function getTotalJobs() external view returns (uint256) {
        return jobCounter;
    }
    
    /**
     * @dev Check if an address has applied to a job
     * @param jobId The ID of the job
     * @param applicant The address to check
     * @return Whether the address has applied
     */
    function hasAppliedToJob(uint256 jobId, address applicant) external view returns (bool) {
        return hasApplied[jobId][applicant];
    }
    
    /**
     * @dev Get job statistics
     * @return totalJobs Total number of jobs
     * @return openJobs Number of open jobs
     * @return filledJobs Number of filled jobs
     * @return closedJobs Number of closed jobs
     */
    function getJobStats() external view returns (
        uint256 totalJobs,
        uint256 openJobs,
        uint256 filledJobs,
        uint256 closedJobs
    ) {
        uint256 openCount = 0;
        uint256 filledCount = 0;
        uint256 closedCount = 0;
        
        for (uint256 i = 1; i <= jobCounter; i++) {
            if (jobs[i].status == JobStatus.OPEN) openCount++;
            else if (jobs[i].status == JobStatus.FILLED) filledCount++;
            else if (jobs[i].status == JobStatus.CLOSED) closedCount++;
        }
        
        return (jobCounter, openCount, filledCount, closedCount);
    }
}
