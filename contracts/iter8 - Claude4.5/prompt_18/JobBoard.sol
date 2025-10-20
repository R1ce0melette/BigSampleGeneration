// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title JobBoard
 * @dev Job board where employers can post jobs and workers can apply by submitting their address
 */
contract JobBoard {
    // Job status enum
    enum JobStatus {
        Open,
        Filled,
        Cancelled
    }

    // Application status enum
    enum ApplicationStatus {
        Pending,
        Accepted,
        Rejected
    }

    // Job structure
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 payment;
        JobStatus status;
        uint256 createdAt;
        uint256 filledAt;
        address selectedWorker;
        uint256 applicationCount;
    }

    // Application structure
    struct Application {
        uint256 id;
        uint256 jobId;
        address worker;
        string coverLetter;
        ApplicationStatus status;
        uint256 appliedAt;
    }

    // Employer statistics
    struct EmployerStats {
        uint256 jobsPosted;
        uint256 jobsFilled;
        uint256 totalSpent;
    }

    // Worker statistics
    struct WorkerStats {
        uint256 applicationsSubmitted;
        uint256 applicationsAccepted;
        uint256 totalEarned;
    }

    // State variables
    address public owner;
    uint256 private jobCounter;
    uint256 private applicationCounter;
    
    mapping(uint256 => Job) private jobs;
    mapping(uint256 => Application) private applications;
    mapping(uint256 => uint256[]) private jobApplicationIds;
    mapping(address => uint256[]) private employerJobIds;
    mapping(address => uint256[]) private workerApplicationIds;
    mapping(uint256 => mapping(address => bool)) private hasApplied;
    mapping(address => EmployerStats) private employerStats;
    mapping(address => WorkerStats) private workerStats;
    
    uint256[] private allJobIds;
    uint256[] private allApplicationIds;

    // Events
    event JobPosted(uint256 indexed jobId, address indexed employer, string title, uint256 payment, uint256 timestamp);
    event JobCancelled(uint256 indexed jobId, address indexed employer);
    event ApplicationSubmitted(uint256 indexed applicationId, uint256 indexed jobId, address indexed worker, uint256 timestamp);
    event ApplicationAccepted(uint256 indexed applicationId, uint256 indexed jobId, address indexed worker);
    event ApplicationRejected(uint256 indexed applicationId, uint256 indexed jobId, address indexed worker);
    event JobFilled(uint256 indexed jobId, address indexed worker, uint256 payment);
    event PaymentReleased(uint256 indexed jobId, address indexed worker, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier jobExists(uint256 jobId) {
        require(jobId > 0 && jobId <= jobCounter, "Job does not exist");
        _;
    }

    modifier applicationExists(uint256 applicationId) {
        require(applicationId > 0 && applicationId <= applicationCounter, "Application does not exist");
        _;
    }

    modifier onlyEmployer(uint256 jobId) {
        require(jobs[jobId].employer == msg.sender, "Not the employer");
        _;
    }

    modifier jobOpen(uint256 jobId) {
        require(jobs[jobId].status == JobStatus.Open, "Job is not open");
        _;
    }

    constructor() {
        owner = msg.sender;
        jobCounter = 0;
        applicationCounter = 0;
    }

    /**
     * @dev Post a new job
     * @param title Job title
     * @param description Job description
     * @return jobId ID of the posted job
     */
    function postJob(string memory title, string memory description) 
        public 
        payable 
        returns (uint256) 
    {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(msg.value > 0, "Must deposit payment for job");

        jobCounter++;
        uint256 jobId = jobCounter;

        Job storage newJob = jobs[jobId];
        newJob.id = jobId;
        newJob.employer = msg.sender;
        newJob.title = title;
        newJob.description = description;
        newJob.payment = msg.value;
        newJob.status = JobStatus.Open;
        newJob.createdAt = block.timestamp;
        newJob.applicationCount = 0;

        allJobIds.push(jobId);
        employerJobIds[msg.sender].push(jobId);

        employerStats[msg.sender].jobsPosted++;

        emit JobPosted(jobId, msg.sender, title, msg.value, block.timestamp);

        return jobId;
    }

    /**
     * @dev Apply to a job
     * @param jobId Job ID
     * @param coverLetter Cover letter or message
     * @return applicationId ID of the application
     */
    function applyToJob(uint256 jobId, string memory coverLetter) 
        public 
        jobExists(jobId)
        jobOpen(jobId)
        returns (uint256) 
    {
        require(!hasApplied[jobId][msg.sender], "Already applied to this job");
        require(jobs[jobId].employer != msg.sender, "Employer cannot apply to own job");

        applicationCounter++;
        uint256 applicationId = applicationCounter;

        Application storage newApplication = applications[applicationId];
        newApplication.id = applicationId;
        newApplication.jobId = jobId;
        newApplication.worker = msg.sender;
        newApplication.coverLetter = coverLetter;
        newApplication.status = ApplicationStatus.Pending;
        newApplication.appliedAt = block.timestamp;

        allApplicationIds.push(applicationId);
        jobApplicationIds[jobId].push(applicationId);
        workerApplicationIds[msg.sender].push(applicationId);
        hasApplied[jobId][msg.sender] = true;

        jobs[jobId].applicationCount++;
        workerStats[msg.sender].applicationsSubmitted++;

        emit ApplicationSubmitted(applicationId, jobId, msg.sender, block.timestamp);

        return applicationId;
    }

    /**
     * @dev Accept an application and fill the job
     * @param applicationId Application ID
     */
    function acceptApplication(uint256 applicationId) 
        public 
        applicationExists(applicationId)
    {
        Application storage application = applications[applicationId];
        uint256 jobId = application.jobId;
        Job storage job = jobs[jobId];

        require(job.employer == msg.sender, "Not the employer");
        require(job.status == JobStatus.Open, "Job is not open");
        require(application.status == ApplicationStatus.Pending, "Application is not pending");

        // Accept this application
        application.status = ApplicationStatus.Accepted;

        // Mark job as filled
        job.status = JobStatus.Filled;
        job.filledAt = block.timestamp;
        job.selectedWorker = application.worker;

        // Reject all other pending applications
        uint256[] memory appIds = jobApplicationIds[jobId];
        for (uint256 i = 0; i < appIds.length; i++) {
            if (appIds[i] != applicationId && applications[appIds[i]].status == ApplicationStatus.Pending) {
                applications[appIds[i]].status = ApplicationStatus.Rejected;
                emit ApplicationRejected(appIds[i], jobId, applications[appIds[i]].worker);
            }
        }

        // Release payment to worker
        uint256 payment = job.payment;
        payable(application.worker).transfer(payment);

        // Update statistics
        employerStats[job.employer].jobsFilled++;
        employerStats[job.employer].totalSpent += payment;
        workerStats[application.worker].applicationsAccepted++;
        workerStats[application.worker].totalEarned += payment;

        emit ApplicationAccepted(applicationId, jobId, application.worker);
        emit JobFilled(jobId, application.worker, payment);
        emit PaymentReleased(jobId, application.worker, payment);
    }

    /**
     * @dev Reject an application
     * @param applicationId Application ID
     */
    function rejectApplication(uint256 applicationId) 
        public 
        applicationExists(applicationId)
    {
        Application storage application = applications[applicationId];
        uint256 jobId = application.jobId;
        Job storage job = jobs[jobId];

        require(job.employer == msg.sender, "Not the employer");
        require(application.status == ApplicationStatus.Pending, "Application is not pending");

        application.status = ApplicationStatus.Rejected;

        emit ApplicationRejected(applicationId, jobId, application.worker);
    }

    /**
     * @dev Cancel a job posting
     * @param jobId Job ID
     */
    function cancelJob(uint256 jobId) 
        public 
        jobExists(jobId)
        onlyEmployer(jobId)
        jobOpen(jobId)
    {
        Job storage job = jobs[jobId];
        
        job.status = JobStatus.Cancelled;

        // Reject all pending applications
        uint256[] memory appIds = jobApplicationIds[jobId];
        for (uint256 i = 0; i < appIds.length; i++) {
            if (applications[appIds[i]].status == ApplicationStatus.Pending) {
                applications[appIds[i]].status = ApplicationStatus.Rejected;
                emit ApplicationRejected(appIds[i], jobId, applications[appIds[i]].worker);
            }
        }

        // Refund payment to employer
        payable(job.employer).transfer(job.payment);

        emit JobCancelled(jobId, msg.sender);
    }

    /**
     * @dev Get job details
     * @param jobId Job ID
     * @return Job details
     */
    function getJob(uint256 jobId) 
        public 
        view 
        jobExists(jobId)
        returns (Job memory) 
    {
        return jobs[jobId];
    }

    /**
     * @dev Get application details
     * @param applicationId Application ID
     * @return Application details
     */
    function getApplication(uint256 applicationId) 
        public 
        view 
        applicationExists(applicationId)
        returns (Application memory) 
    {
        return applications[applicationId];
    }

    /**
     * @dev Get all jobs
     * @return Array of all jobs
     */
    function getAllJobs() public view returns (Job[] memory) {
        Job[] memory allJobs = new Job[](allJobIds.length);
        
        for (uint256 i = 0; i < allJobIds.length; i++) {
            allJobs[i] = jobs[allJobIds[i]];
        }
        
        return allJobs;
    }

    /**
     * @dev Get jobs by status
     * @param status Job status
     * @return Array of jobs with the specified status
     */
    function getJobsByStatus(JobStatus status) public view returns (Job[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allJobIds.length; i++) {
            if (jobs[allJobIds[i]].status == status) {
                count++;
            }
        }

        Job[] memory result = new Job[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allJobIds.length; i++) {
            Job memory job = jobs[allJobIds[i]];
            if (job.status == status) {
                result[index] = job;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get open jobs
     * @return Array of open jobs
     */
    function getOpenJobs() public view returns (Job[] memory) {
        return getJobsByStatus(JobStatus.Open);
    }

    /**
     * @dev Get filled jobs
     * @return Array of filled jobs
     */
    function getFilledJobs() public view returns (Job[] memory) {
        return getJobsByStatus(JobStatus.Filled);
    }

    /**
     * @dev Get applications for a job
     * @param jobId Job ID
     * @return Array of application IDs
     */
    function getJobApplicationIds(uint256 jobId) 
        public 
        view 
        jobExists(jobId)
        returns (uint256[] memory) 
    {
        return jobApplicationIds[jobId];
    }

    /**
     * @dev Get application details for a job
     * @param jobId Job ID
     * @return Array of applications
     */
    function getJobApplications(uint256 jobId) 
        public 
        view 
        jobExists(jobId)
        returns (Application[] memory) 
    {
        uint256[] memory appIds = jobApplicationIds[jobId];
        Application[] memory result = new Application[](appIds.length);

        for (uint256 i = 0; i < appIds.length; i++) {
            result[i] = applications[appIds[i]];
        }

        return result;
    }

    /**
     * @dev Get pending applications for a job
     * @param jobId Job ID
     * @return Array of pending applications
     */
    function getPendingApplications(uint256 jobId) 
        public 
        view 
        jobExists(jobId)
        returns (Application[] memory) 
    {
        uint256[] memory appIds = jobApplicationIds[jobId];
        
        uint256 count = 0;
        for (uint256 i = 0; i < appIds.length; i++) {
            if (applications[appIds[i]].status == ApplicationStatus.Pending) {
                count++;
            }
        }

        Application[] memory result = new Application[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < appIds.length; i++) {
            if (applications[appIds[i]].status == ApplicationStatus.Pending) {
                result[index] = applications[appIds[i]];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get employer's jobs
     * @param employer Employer address
     * @return Array of job IDs
     */
    function getEmployerJobIds(address employer) public view returns (uint256[] memory) {
        return employerJobIds[employer];
    }

    /**
     * @dev Get employer's job details
     * @param employer Employer address
     * @return Array of jobs
     */
    function getEmployerJobs(address employer) public view returns (Job[] memory) {
        uint256[] memory jobIds = employerJobIds[employer];
        Job[] memory result = new Job[](jobIds.length);

        for (uint256 i = 0; i < jobIds.length; i++) {
            result[i] = jobs[jobIds[i]];
        }

        return result;
    }

    /**
     * @dev Get worker's applications
     * @param worker Worker address
     * @return Array of application IDs
     */
    function getWorkerApplicationIds(address worker) public view returns (uint256[] memory) {
        return workerApplicationIds[worker];
    }

    /**
     * @dev Get worker's application details
     * @param worker Worker address
     * @return Array of applications
     */
    function getWorkerApplications(address worker) public view returns (Application[] memory) {
        uint256[] memory appIds = workerApplicationIds[worker];
        Application[] memory result = new Application[](appIds.length);

        for (uint256 i = 0; i < appIds.length; i++) {
            result[i] = applications[appIds[i]];
        }

        return result;
    }

    /**
     * @dev Get employer statistics
     * @param employer Employer address
     * @return EmployerStats structure
     */
    function getEmployerStats(address employer) public view returns (EmployerStats memory) {
        return employerStats[employer];
    }

    /**
     * @dev Get worker statistics
     * @param worker Worker address
     * @return WorkerStats structure
     */
    function getWorkerStats(address worker) public view returns (WorkerStats memory) {
        return workerStats[worker];
    }

    /**
     * @dev Check if worker has applied to a job
     * @param jobId Job ID
     * @param worker Worker address
     * @return true if worker has applied
     */
    function hasWorkerApplied(uint256 jobId, address worker) 
        public 
        view 
        jobExists(jobId)
        returns (bool) 
    {
        return hasApplied[jobId][worker];
    }

    /**
     * @dev Get total job count
     * @return Total number of jobs
     */
    function getTotalJobCount() public view returns (uint256) {
        return jobCounter;
    }

    /**
     * @dev Get total application count
     * @return Total number of applications
     */
    function getTotalApplicationCount() public view returns (uint256) {
        return applicationCounter;
    }

    /**
     * @dev Get job count by status
     * @param status Job status
     * @return Count of jobs with the specified status
     */
    function getJobCountByStatus(JobStatus status) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allJobIds.length; i++) {
            if (jobs[allJobIds[i]].status == status) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get recent jobs
     * @param count Number of recent jobs to retrieve
     * @return Array of recent jobs
     */
    function getRecentJobs(uint256 count) public view returns (Job[] memory) {
        uint256 totalCount = allJobIds.length;
        uint256 resultCount = count > totalCount ? totalCount : count;

        Job[] memory result = new Job[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = jobs[allJobIds[totalCount - 1 - i]];
        }

        return result;
    }

    /**
     * @dev Get contract balance
     * @return Current contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
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
