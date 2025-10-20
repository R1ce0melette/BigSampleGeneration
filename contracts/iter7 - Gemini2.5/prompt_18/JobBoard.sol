// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title JobBoard
 * @dev A contract for a simple job board where employers can post jobs and workers can apply.
 */
contract JobBoard {
    // Struct to represent a job posting.
    struct Job {
        uint256 id;
        string title;
        string description;
        address employer;
        bool isOpen;
        address[] applicants;
    }

    // Counter for generating unique job IDs.
    uint256 private _jobIds;

    // Mapping from job ID to the Job struct.
    mapping(uint256 => Job) public jobs;

    /**
     * @dev Emitted when a new job is posted.
     * @param jobId The unique ID of the job.
     * @param title The title of the job.
     * @param employer The address of the employer who posted the job.
     */
    event JobPosted(
        uint256 indexed jobId,
        string title,
        address indexed employer
    );

    /**
     * @dev Emitted when a worker applies for a job.
     * @param jobId The ID of the job applied for.
     * @param applicant The address of the worker who applied.
     */
    event JobApplied(
        uint256 indexed jobId,
        address indexed applicant
    );

    /**
     * @dev Emitted when a job is closed.
     * @param jobId The ID of the closed job.
     */
    event JobClosed(uint256 indexed jobId);

    /**
     * @dev Posts a new job to the board.
     * @param _title The title of the job.
     * @param _description A description of the job.
     */
    function postJob(string memory _title, string memory _description) public {
        require(bytes(_title).length > 0, "Job title cannot be empty.");
        _jobIds++;
        uint256 newJobId = _jobIds;

        jobs[newJobId] = Job({
            id: newJobId,
            title: _title,
            description: _description,
            employer: msg.sender,
            isOpen: true,
            applicants: new address[](0)
        });

        emit JobPosted(newJobId, _title, msg.sender);
    }

    /**
     * @dev Allows a worker to apply for an open job.
     * @param _jobId The ID of the job to apply for.
     */
    function applyForJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        require(job.id != 0, "Job does not exist.");
        require(job.isOpen, "This job is no longer open.");
        
        // Check if the user has already applied.
        for (uint i = 0; i < job.applicants.length; i++) {
            require(job.applicants[i] != msg.sender, "You have already applied for this job.");
        }

        job.applicants.push(msg.sender);
        emit JobApplied(_jobId, msg.sender);
    }

    /**
     * @dev Allows the employer to close a job posting.
     * @param _jobId The ID of the job to close.
     */
    function closeJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        require(job.id != 0, "Job does not exist.");
        require(job.employer == msg.sender, "Only the employer can close the job.");
        require(job.isOpen, "This job is already closed.");

        job.isOpen = false;
        emit JobClosed(_jobId);
    }

    /**
     * @dev Retrieves the list of applicants for a specific job.
     * Only the employer of the job can view the applicants.
     * @param _jobId The ID of the job.
     * @return An array of applicant addresses.
     */
    function getApplicants(uint256 _jobId) public view returns (address[] memory) {
        Job storage job = jobs[_jobId];
        require(job.id != 0, "Job does not exist.");
        require(job.employer == msg.sender, "Only the employer can view applicants.");
        return job.applicants;
    }
}
