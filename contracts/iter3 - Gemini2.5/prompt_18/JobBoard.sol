// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title JobBoard
 * @dev A contract for a simple job board where employers can post jobs
 * and workers can apply.
 */
contract JobBoard {
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 reward; // in wei
        bool isOpen;
        address[] applicants;
    }

    address public owner;
    uint256 private _jobIdCounter;
    Job[] public jobs;

    /**
     * @dev Emitted when a new job is posted.
     * @param jobId The unique ID of the job.
     * @param employer The address of the employer who posted the job.
     * @param title The title of the job.
     * @param reward The reward for completing the job, in wei.
     */
    event JobPosted(
        uint256 indexed jobId,
        address indexed employer,
        string title,
        uint256 reward
    );

    /**
     * @dev Emitted when a worker applies for a job.
     * @param jobId The ID of the job applied for.
     * @param applicant The address of the worker who applied.
     */
    event JobApplied(uint256 indexed jobId, address indexed applicant);

    /**
     * @dev Emitted when a job is closed by the employer.
     * @param jobId The ID of the job that was closed.
     */
    event JobClosed(uint256 indexed jobId);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the contract owner upon deployment.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows an employer to post a new job.
     * @param _title The title of the job.
     * @param _description A description of the job.
     * @param _reward The reward for the job in wei.
     */
    function postJob(string memory _title, string memory _description, uint256 _reward) public {
        require(bytes(_title).length > 0, "Job title cannot be empty.");
        
        _jobIdCounter++;
        Job memory newJob;
        newJob.id = _jobIdCounter;
        newJob.employer = msg.sender;
        newJob.title = _title;
        newJob.description = _description;
        newJob.reward = _reward;
        newJob.isOpen = true;
        
        jobs.push(newJob);

        emit JobPosted(_jobIdCounter, msg.sender, _title, _reward);
    }

    /**
     * @dev Allows a worker to apply for an open job.
     * A worker cannot apply for the same job more than once.
     * @param _jobId The ID of the job to apply for.
     */
    function applyForJob(uint256 _jobId) public {
        require(_jobId > 0 && _jobId <= jobs.length, "Job ID is invalid.");
        
        Job storage job = jobs[_jobId - 1];
        require(job.isOpen, "This job is no longer open.");
        require(msg.sender != job.employer, "Employers cannot apply for their own jobs.");

        // Check if the user has already applied
        for (uint256 i = 0; i < job.applicants.length; i++) {
            require(job.applicants[i] != msg.sender, "You have already applied for this job.");
        }

        job.applicants.push(msg.sender);
        emit JobApplied(_jobId, msg.sender);
    }

    /**
     * @dev Allows an employer to close a job they posted.
     * @param _jobId The ID of the job to close.
     */
    function closeJob(uint256 _jobId) public {
        require(_jobId > 0 && _jobId <= jobs.length, "Job ID is invalid.");
        
        Job storage job = jobs[_jobId - 1];
        require(msg.sender == job.employer, "Only the employer can close this job.");
        require(job.isOpen, "This job is already closed.");

        job.isOpen = false;
        emit JobClosed(_jobId);
    }

    /**
     * @dev Retrieves the details of a specific job.
     * @param _jobId The ID of the job.
     * @return A tuple containing the job's details.
     */
    function getJob(uint256 _jobId) public view returns (uint256, address, string memory, string memory, uint256, bool) {
        require(_jobId > 0 && _jobId <= jobs.length, "Job ID is invalid.");
        Job storage job = jobs[_jobId - 1];
        return (job.id, job.employer, job.title, job.description, job.reward, job.isOpen);
    }

    /**
     * @dev Retrieves the list of applicants for a specific job.
     * @param _jobId The ID of the job.
     * @return An array of applicant addresses.
     */
    function getApplicants(uint256 _jobId) public view returns (address[] memory) {
        require(_jobId > 0 && _jobId <= jobs.length, "Job ID is invalid.");
        return jobs[_jobId - 1].applicants;
    }

    /**
     * @dev Returns the total number of jobs posted.
     */
    function getTotalJobs() public view returns (uint256) {
        return jobs.length;
    }
}
