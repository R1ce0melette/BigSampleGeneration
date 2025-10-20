// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title JobBoard
 * @dev A contract for a simple job board where employers can post jobs
 * and workers can apply.
 */
contract JobBoard {
    address public owner;
    uint256 public jobCounter;

    struct Job {
        uint256 id;
        address employer;
        string description;
        uint256 reward;
        bool isOpen;
        address[] applicants;
    }

    mapping(uint256 => Job) public jobs;
    mapping(uint256 => mapping(address => bool)) public hasApplied;

    event JobPosted(uint256 indexed jobId, address indexed employer, string description, uint256 reward);
    event JobApplied(uint256 indexed jobId, address indexed applicant);
    event JobClosed(uint256 indexed jobId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        jobCounter = 0;
    }

    /**
     * @dev Allows an employer to post a new job.
     * @param _description A description of the job.
     */
    function postJob(string memory _description) external payable {
        require(bytes(_description).length > 0, "Description cannot be empty.");
        require(msg.value > 0, "Reward must be greater than zero.");

        jobCounter++;
        jobs[jobCounter] = Job({
            id: jobCounter,
            employer: msg.sender,
            description: _description,
            reward: msg.value,
            isOpen: true,
            applicants: new address[](0)
        });

        emit JobPosted(jobCounter, msg.sender, _description, msg.value);
    }

    /**
     * @dev Allows a worker to apply for an open job.
     * @param _jobId The ID of the job to apply for.
     */
    function applyForJob(uint256 _jobId) external {
        Job storage job = jobs[_jobId];
        require(job.isOpen, "Job is not open.");
        require(!hasApplied[_jobId][msg.sender], "You have already applied for this job.");

        job.applicants.push(msg.sender);
        hasApplied[_jobId][msg.sender] = true;

        emit JobApplied(_jobId, msg.sender);
    }

    /**
     * @dev Allows the employer to close a job and award the reward to a selected worker.
     * @param _jobId The ID of the job to close.
     * @param _worker The address of the worker to receive the reward.
     */
    function closeJobAndAward(uint256 _jobId, address payable _worker) external {
        Job storage job = jobs[_jobId];
        require(job.employer == msg.sender, "Only the employer can close the job.");
        require(job.isOpen, "Job is already closed.");
        require(hasApplied[_jobId][_worker], "Selected worker has not applied for this job.");

        job.isOpen = false;
        (bool success, ) = _worker.call{value: job.reward}("");
        require(success, "Reward transfer failed.");

        emit JobClosed(_jobId);
    }

    /**
     * @dev Allows the employer to cancel a job and get a refund if no one has applied.
     * @param _jobId The ID of the job to cancel.
     */
    function cancelJob(uint256 _jobId) external {
        Job storage job = jobs[_jobId];
        require(job.employer == msg.sender, "Only the employer can cancel the job.");
        require(job.isOpen, "Job is already closed.");
        require(job.applicants.length == 0, "Cannot cancel a job with applicants.");

        job.isOpen = false;
        (bool success, ) = payable(msg.sender).call{value: job.reward}("");
        require(success, "Refund failed.");

        emit JobClosed(_jobId);
    }

    /**
     * @dev Returns the list of applicants for a specific job.
     * @param _jobId The ID of the job.
     * @return An array of applicant addresses.
     */
    function getApplicants(uint256 _jobId) external view returns (address[] memory) {
        return jobs[_jobId].applicants;
    }
}
