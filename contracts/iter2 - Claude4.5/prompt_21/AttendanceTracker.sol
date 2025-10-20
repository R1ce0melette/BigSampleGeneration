// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttendanceTracker {
    address public organizer;
    
    struct Event {
        uint256 eventId;
        string eventName;
        string location;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        address[] attendees;
    }
    
    struct AttendanceRecord {
        uint256 eventId;
        address attendee;
        uint256 checkInTime;
    }
    
    uint256 public eventCount;
    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => bool)) public hasCheckedIn;
    mapping(uint256 => mapping(address => uint256)) public checkInTime;
    mapping(address => uint256[]) public userAttendedEvents;
    
    event EventCreated(uint256 indexed eventId, string eventName, uint256 startTime, uint256 endTime);
    event CheckedIn(uint256 indexed eventId, address indexed attendee, uint256 timestamp);
    event EventActivated(uint256 indexed eventId);
    event EventDeactivated(uint256 indexed eventId);
    
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer can call this function");
        _;
    }
    
    modifier eventExists(uint256 _eventId) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        _;
    }
    
    constructor() {
        organizer = msg.sender;
    }
    
    function createEvent(
        string memory _eventName,
        string memory _location,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOrganizer returns (uint256) {
        require(bytes(_eventName).length > 0, "Event name cannot be empty");
        require(_startTime < _endTime, "Start time must be before end time");
        require(_endTime > block.timestamp, "End time must be in the future");
        
        eventCount++;
        
        Event storage newEvent = events[eventCount];
        newEvent.eventId = eventCount;
        newEvent.eventName = _eventName;
        newEvent.location = _location;
        newEvent.startTime = _startTime;
        newEvent.endTime = _endTime;
        newEvent.isActive = true;
        
        emit EventCreated(eventCount, _eventName, _startTime, _endTime);
        
        return eventCount;
    }
    
    function checkIn(uint256 _eventId) external eventExists(_eventId) {
        Event storage eventData = events[_eventId];
        
        require(eventData.isActive, "Event is not active");
        require(block.timestamp >= eventData.startTime, "Event has not started yet");
        require(block.timestamp <= eventData.endTime, "Event has ended");
        require(!hasCheckedIn[_eventId][msg.sender], "Already checked in");
        
        hasCheckedIn[_eventId][msg.sender] = true;
        checkInTime[_eventId][msg.sender] = block.timestamp;
        eventData.attendees.push(msg.sender);
        userAttendedEvents[msg.sender].push(_eventId);
        
        emit CheckedIn(_eventId, msg.sender, block.timestamp);
    }
    
    function activateEvent(uint256 _eventId) external onlyOrganizer eventExists(_eventId) {
        require(!events[_eventId].isActive, "Event is already active");
        events[_eventId].isActive = true;
        
        emit EventActivated(_eventId);
    }
    
    function deactivateEvent(uint256 _eventId) external onlyOrganizer eventExists(_eventId) {
        require(events[_eventId].isActive, "Event is already inactive");
        events[_eventId].isActive = false;
        
        emit EventDeactivated(_eventId);
    }
    
    function getEvent(uint256 _eventId) external view eventExists(_eventId) returns (
        string memory eventName,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 attendeeCount
    ) {
        Event storage eventData = events[_eventId];
        
        return (
            eventData.eventName,
            eventData.location,
            eventData.startTime,
            eventData.endTime,
            eventData.isActive,
            eventData.attendees.length
        );
    }
    
    function getAttendees(uint256 _eventId) external view eventExists(_eventId) returns (address[] memory) {
        return events[_eventId].attendees;
    }
    
    function getAttendeeCount(uint256 _eventId) external view eventExists(_eventId) returns (uint256) {
        return events[_eventId].attendees.length;
    }
    
    function hasAttendeeCheckedIn(uint256 _eventId, address _attendee) external view eventExists(_eventId) returns (bool) {
        return hasCheckedIn[_eventId][_attendee];
    }
    
    function getCheckInTime(uint256 _eventId, address _attendee) external view eventExists(_eventId) returns (uint256) {
        require(hasCheckedIn[_eventId][_attendee], "Attendee has not checked in");
        return checkInTime[_eventId][_attendee];
    }
    
    function getUserAttendedEvents(address _user) external view returns (uint256[] memory) {
        return userAttendedEvents[_user];
    }
    
    function getAttendanceRecord(uint256 _eventId, address _attendee) external view eventExists(_eventId) returns (
        bool checkedIn,
        uint256 timestamp
    ) {
        return (
            hasCheckedIn[_eventId][_attendee],
            checkInTime[_eventId][_attendee]
        );
    }
    
    function getActiveEvents() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive && block.timestamp <= events[i].endTime) {
                activeCount++;
            }
        }
        
        uint256[] memory activeEvents = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive && block.timestamp <= events[i].endTime) {
                activeEvents[index] = i;
                index++;
            }
        }
        
        return activeEvents;
    }
    
    function transferOrganizer(address _newOrganizer) external onlyOrganizer {
        require(_newOrganizer != address(0), "New organizer cannot be zero address");
        require(_newOrganizer != organizer, "New organizer is the same as current");
        
        organizer = _newOrganizer;
    }
}
