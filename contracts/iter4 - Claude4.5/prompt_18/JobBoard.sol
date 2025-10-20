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
    event JobApplicationSubmitted(uint256 indexed jobId, address indexed applicant);
    event WorkerSelected(uint256 indexed jobId, address indexed worker);
    event JobClosed(uint256 indexed jobId);
    event PaymentReleased(uint256 indexed jobId, address indexed worker, uint256 amount);
    
    /**
     * @dev Allows employers to post a job
     * @param _title The job title
     * @param _description The job description
     */
    function postJob(string memory _title, string memory _description) external payable {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(msg.value > 0, "Payment must be greater than 0");
        
        jobCount++;
        
        Job storage newJob = jobs[jobCount];
        newJob.id = jobCount;
        newJob.employer = msg.sender;
        newJob.title = _title;
        newJob.description = _description;
        newJob.payment = msg.value;
        newJob.status = JobStatus.OPEN;
        newJob.postedAt = block.timestamp;
        
        emit JobPosted(jobCount, msg.sender, _title, msg.value);
    }
    
    /**
     * @dev Allows workers to apply for a job
     * @param _jobId The ID of the job to apply for
     */
    function applyForJob(uint256 _jobId) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(msg.sender != job.employer, "Employer cannot apply to own job");
        require(!hasApplied[_jobId][msg.sender], "Already applied to this job");
        
        job.applicants.push(msg.sender);
        hasApplied[_jobId][msg.sender] = true;
        
        emit JobApplicationSubmitted(_jobId, msg.sender);
    }
    
    /**
     * @dev Allows the employer to select a worker for the job
     * @param _jobId The ID of the job
     * @param _worker The address of the selected worker
     */
    function selectWorker(uint256 _jobId, address _worker) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can select worker");
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(hasApplied[_jobId][_worker], "Worker has not applied for this job");
        
        job.selectedWorker = _worker;
        job.status = JobStatus.FILLED;
        
        emit WorkerSelected(_jobId, _worker);
    }
    
    /**
     * @dev Allows the employer to release payment to the selected worker
     * @param _jobId The ID of the job
     */
    function releasePayment(uint256 _jobId) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can release payment");
        require(job.status == JobStatus.FILLED, "Job is not filled");
        require(job.selectedWorker != address(0), "No worker selected");
        require(job.payment > 0, "Payment already released");
        
        uint256 payment = job.payment;
        job.payment = 0;
        
        (bool success, ) = job.selectedWorker.call{value: payment}("");
        require(success, "Payment transfer failed");
        
        emit PaymentReleased(_jobId, job.selectedWorker, payment);
    }
    
    /**
     * @dev Allows the employer to close a job without selecting anyone (refund)
     * @param _jobId The ID of the job
     */
    function closeJob(uint256 _jobId) external {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can close job");
        require(job.status == JobStatus.OPEN, "Job is not open");
        
        job.status = JobStatus.CLOSED;
        
        // Refund the payment to employer
        uint256 payment = job.payment;
        job.payment = 0;
        
        (bool success, ) = job.employer.call{value: payment}("");
        require(success, "Refund transfer failed");
        
        emit JobClosed(_jobId);
    }
    
    /**
     * @dev Returns the details of a job
     * @param _jobId The ID of the job
     * @return id The job ID
     * @return employer The employer's address
     * @return title The job title
     * @return description The job description
     * @return payment The job payment
     * @return status The job status
     * @return postedAt When the job was posted
     * @return applicantCount The number of applicants
     * @return selectedWorker The selected worker (if any)
     */
    function getJob(uint256 _jobId) external view returns (
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
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        Job storage job = jobs[_jobId];
        
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
     * @dev Returns all applicants for a job
     * @param _jobId The ID of the job
     * @return Array of applicant addresses
     */
    function getJobApplicants(uint256 _jobId) external view returns (address[] memory) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        return jobs[_jobId].applicants;
    }
    
    /**
     * @dev Returns all open jobs
     * @return Array of open job IDs
     */
    function getOpenJobs() external view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        // Count open jobs
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                openCount++;
            }
        }
        
        // Create array of open job IDs
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
     * @dev Returns jobs posted by a specific employer
     * @param _employer The address of the employer
     * @return Array of job IDs
     */
    function getJobsByEmployer(address _employer) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count jobs by employer
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == _employer) {
                count++;
            }
        }
        
        // Create array of job IDs
        uint256[] memory employerJobs = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].employer == _employer) {
                employerJobs[index] = i;
                index++;
            }
        }
        
        return employerJobs;
    }
    
    /**
     * @dev Returns jobs the caller has posted
     * @return Array of job IDs
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
     * @dev Returns jobs the caller has applied to
     * @return Array of job IDs
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
     * @dev Checks if a user has applied for a specific job
     * @param _jobId The ID of the job
     * @param _applicant The address of the applicant
     * @return True if the applicant has applied, false otherwise
     */
    function hasUserApplied(uint256 _jobId, address _applicant) external view returns (bool) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        return hasApplied[_jobId][_applicant];
    }
    
    /**
     * @dev Returns the job status as a string
     * @param _jobId The ID of the job
     * @return The status as a string
     */
    function getJobStatusString(uint256 _jobId) external view returns (string memory) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        
        JobStatus status = jobs[_jobId].status;
        
        if (status == JobStatus.OPEN) return "OPEN";
        if (status == JobStatus.CLOSED) return "CLOSED";
        if (status == JobStatus.FILLED) return "FILLED";
        
        return "UNKNOWN";
    }
}
