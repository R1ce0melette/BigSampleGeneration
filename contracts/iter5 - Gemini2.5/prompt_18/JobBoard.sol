// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title JobBoard
 * @dev A contract for a simple job board where employers can post jobs and workers can apply.
 */
contract JobBoard {

    struct Job {
        uint256 id;
        string title;
        string description;
        address employer;
        bool isOpen;
    }

    struct Application {
        uint256 jobId;
        address applicant;
        uint256 timestamp;
    }

    uint256 private nextJobId;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => address[]) public applicants; // Job ID to list of applicants

    event JobPosted(uint256 indexed jobId, string title, address indexed employer);
    event Applied(uint256 indexed jobId, address indexed applicant);

    /**
     * @dev Allows an employer to post a new job.
     * @param _title The title of the job.
     * @param _description A description of the job.
     */
    function postJob(string memory _title, string memory _description) public {
        require(bytes(_title).length > 0, "Job title cannot be empty.");
        
        uint256 jobId = nextJobId;
        jobs[jobId] = Job({
            id: jobId,
            title: _title,
            description: _description,
            employer: msg.sender,
            isOpen: true
        });
        
        nextJobId++;
        emit JobPosted(jobId, _title, msg.sender);
    }

    /**
     * @dev Allows a worker to apply for a job.
     * @param _jobId The ID of the job to apply for.
     */
    function apply(uint256 _jobId) public {
        require(jobs[_jobId].isOpen, "This job is no longer open.");
        
        // Optional: Check if the user has already applied
        for (uint i = 0; i < applicants[_jobId].length; i++) {
            require(applicants[_jobId][i] != msg.sender, "You have already applied for this job.");
        }

        applicants[_jobId].push(msg.sender);
        emit Applied(_jobId, msg.sender);
    }

    /**
     * @dev Allows an employer to close a job posting.
     * @param _jobId The ID of the job to close.
     */
    function closeJob(uint256 _jobId) public {
        require(jobs[_jobId].employer == msg.sender, "Only the employer can close the job.");
        jobs[_jobId].isOpen = false;
    }

    /**
     * @dev Retrieves the details of a job.
     * @param _jobId The ID of the job.
     * @return The job's details.
     */
    function getJob(uint256 _jobId) public view returns (uint256, string memory, string memory, address, bool) {
        Job storage job = jobs[_jobId];
        return (job.id, job.title, job.description, job.employer, job.isOpen);
    }

    /**
     * @dev Retrieves the list of applicants for a job.
     * @param _jobId The ID of the job.
     * @return An array of applicant addresses.
     */
    function getApplicants(uint256 _jobId) public view returns (address[] memory) {
        return applicants[_jobId];
    }
}
