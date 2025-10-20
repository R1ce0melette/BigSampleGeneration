// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventAttendance {
    address public organizer;

    struct Event {
        uint256 id;
        string name;
        string location;
        uint256 startTime;
        uint256 endTime;
        bool active;
        uint256 attendeeCount;
    }

    struct Attendance {
        address attendee;
        uint256 checkInTime;
    }

    uint256 public eventCount;
    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => bool)) public hasCheckedIn;
    mapping(uint256 => mapping(address => uint256)) public checkInTimes;
    mapping(uint256 => address[]) public eventAttendees;

    event EventCreated(uint256 indexed eventId, string name, uint256 startTime, uint256 endTime);
    event CheckedIn(uint256 indexed eventId, address indexed attendee, uint256 timestamp);
    event EventActivated(uint256 indexed eventId);
    event EventDeactivated(uint256 indexed eventId);

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer can perform this action");
        _;
    }

    modifier eventExists(uint256 eventId) {
        require(eventId > 0 && eventId <= eventCount, "Event does not exist");
        _;
    }

    constructor() {
        organizer = msg.sender;
    }

    function createEvent(
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime
    ) external onlyOrganizer {
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(endTime > startTime, "End time must be after start time");
        require(startTime > block.timestamp, "Start time must be in the future");

        eventCount++;

        events[eventCount] = Event({
            id: eventCount,
            name: name,
            location: location,
            startTime: startTime,
            endTime: endTime,
            active: true,
            attendeeCount: 0
        });

        emit EventCreated(eventCount, name, startTime, endTime);
    }

    function checkIn(uint256 eventId) external eventExists(eventId) {
        Event storage eventData = events[eventId];
        require(eventData.active, "Event is not active");
        require(block.timestamp >= eventData.startTime, "Event has not started yet");
        require(block.timestamp <= eventData.endTime, "Event has already ended");
        require(!hasCheckedIn[eventId][msg.sender], "Already checked in");

        hasCheckedIn[eventId][msg.sender] = true;
        checkInTimes[eventId][msg.sender] = block.timestamp;
        eventAttendees[eventId].push(msg.sender);
        eventData.attendeeCount++;

        emit CheckedIn(eventId, msg.sender, block.timestamp);
    }

    function activateEvent(uint256 eventId) external onlyOrganizer eventExists(eventId) {
        require(!events[eventId].active, "Event is already active");
        events[eventId].active = true;
        emit EventActivated(eventId);
    }

    function deactivateEvent(uint256 eventId) external onlyOrganizer eventExists(eventId) {
        require(events[eventId].active, "Event is already inactive");
        events[eventId].active = false;
        emit EventDeactivated(eventId);
    }

    function getEvent(uint256 eventId) external view eventExists(eventId) returns (
        uint256 id,
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        bool active,
        uint256 attendeeCount
    ) {
        Event memory eventData = events[eventId];
        return (
            eventData.id,
            eventData.name,
            eventData.location,
            eventData.startTime,
            eventData.endTime,
            eventData.active,
            eventData.attendeeCount
        );
    }

    function hasAttendeeCheckedIn(uint256 eventId, address attendee) external view eventExists(eventId) returns (bool) {
        return hasCheckedIn[eventId][attendee];
    }

    function getCheckInTime(uint256 eventId, address attendee) external view eventExists(eventId) returns (uint256) {
        require(hasCheckedIn[eventId][attendee], "Attendee has not checked in");
        return checkInTimes[eventId][attendee];
    }

    function getEventAttendees(uint256 eventId) external view eventExists(eventId) returns (address[] memory) {
        return eventAttendees[eventId];
    }

    function getAttendeeCount(uint256 eventId) external view eventExists(eventId) returns (uint256) {
        return events[eventId].attendeeCount;
    }

    function getActiveEvents() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].active) {
                activeCount++;
            }
        }

        uint256[] memory activeEventIds = new uint256[](activeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].active) {
                activeEventIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return activeEventIds;
    }

    function changeOrganizer(address newOrganizer) external onlyOrganizer {
        require(newOrganizer != address(0), "Invalid organizer address");
        organizer = newOrganizer;
    }
}
