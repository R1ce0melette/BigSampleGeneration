// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    enum JobStatus { OPEN, CLOSED, FILLED }
    
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 payment;
        JobStatus status;
        uint256 postedTime;
        address selectedWorker;
    }
    
    struct Application {
        address worker;
        uint256 appliedTime;
        string message;
    }
    
    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => Application[]) public jobApplications;
    mapping(uint256 => mapping(address => bool)) public hasApplied;
    
    event JobPosted(uint256 indexed jobId, address indexed employer, string title, uint256 payment);
    event ApplicationSubmitted(uint256 indexed jobId, address indexed worker, uint256 applicationIndex);
    event WorkerSelected(uint256 indexed jobId, address indexed worker);
    event JobClosed(uint256 indexed jobId);
    event PaymentReleased(uint256 indexed jobId, address indexed worker, uint256 amount);
    
    function postJob(string memory _title, string memory _description) external payable {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(msg.value > 0, "Payment must be greater than zero");
        
        jobCount++;
        
        jobs[jobCount] = Job({
            id: jobCount,
            employer: msg.sender,
            title: _title,
            description: _description,
            payment: msg.value,
            status: JobStatus.OPEN,
            postedTime: block.timestamp,
            selectedWorker: address(0)
        });
        
        emit JobPosted(jobCount, msg.sender, _title, msg.value);
    }
    
    function applyForJob(uint256 _jobId, string memory _message) external {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        
        Job storage job = jobs[_jobId];
        
        require(job.status == JobStatus.OPEN, "Job is not open for applications");
        require(msg.sender != job.employer, "Employer cannot apply to own job");
        require(!hasApplied[_jobId][msg.sender], "Already applied to this job");
        
        jobApplications[_jobId].push(Application({
            worker: msg.sender,
            appliedTime: block.timestamp,
            message: _message
        }));
        
        hasApplied[_jobId][msg.sender] = true;
        
        emit ApplicationSubmitted(_jobId, msg.sender, jobApplications[_jobId].length - 1);
    }
    
    function selectWorker(uint256 _jobId, uint256 _applicationIndex) external {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can select worker");
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(_applicationIndex < jobApplications[_jobId].length, "Invalid application index");
        
        address selectedWorker = jobApplications[_jobId][_applicationIndex].worker;
        
        job.selectedWorker = selectedWorker;
        job.status = JobStatus.FILLED;
        
        emit WorkerSelected(_jobId, selectedWorker);
    }
    
    function releasePayment(uint256 _jobId) external {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can release payment");
        require(job.status == JobStatus.FILLED, "Job is not filled");
        require(job.selectedWorker != address(0), "No worker selected");
        
        address payable worker = payable(job.selectedWorker);
        uint256 payment = job.payment;
        
        job.payment = 0;
        
        (bool success, ) = worker.call{value: payment}("");
        require(success, "Payment transfer failed");
        
        emit PaymentReleased(_jobId, worker, payment);
    }
    
    function closeJob(uint256 _jobId) external {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        
        Job storage job = jobs[_jobId];
        
        require(msg.sender == job.employer, "Only employer can close job");
        require(job.status == JobStatus.OPEN, "Job is not open");
        
        job.status = JobStatus.CLOSED;
        
        uint256 refund = job.payment;
        job.payment = 0;
        
        (bool success, ) = payable(job.employer).call{value: refund}("");
        require(success, "Refund transfer failed");
        
        emit JobClosed(_jobId);
    }
    
    function getJob(uint256 _jobId) external view returns (
        uint256 id,
        address employer,
        string memory title,
        string memory description,
        uint256 payment,
        JobStatus status,
        uint256 postedTime,
        address selectedWorker
    ) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        
        Job memory job = jobs[_jobId];
        
        return (
            job.id,
            job.employer,
            job.title,
            job.description,
            job.payment,
            job.status,
            job.postedTime,
            job.selectedWorker
        );
    }
    
    function getJobApplications(uint256 _jobId) external view returns (Application[] memory) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        return jobApplications[_jobId];
    }
    
    function getApplicationCount(uint256 _jobId) external view returns (uint256) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        return jobApplications[_jobId].length;
    }
    
    function hasUserApplied(uint256 _jobId, address _user) external view returns (bool) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist");
        return hasApplied[_jobId][_user];
    }
}
