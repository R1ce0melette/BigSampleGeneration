// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AttendanceLogger
 * @dev A contract that logs attendance for events where users can check in using their wallet address
 */
contract AttendanceLogger {
    address public organizer;
    
    struct Event {
        uint256 id;
        string name;
        string location;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        address[] attendees;
    }
    
    uint256 public eventCount;
    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => bool)) public hasCheckedIn;
    mapping(uint256 => mapping(address => uint256)) public checkInTime;
    
    // Events
    event EventCreated(uint256 indexed eventId, string name, uint256 startTime, uint256 endTime);
    event CheckedIn(uint256 indexed eventId, address indexed attendee, uint256 timestamp);
    event EventClosed(uint256 indexed eventId);
    
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer can perform this action");
        _;
    }
    
    constructor() {
        organizer = msg.sender;
    }
    
    /**
     * @dev Create a new event
     * @param name The event name
     * @param location The event location
     * @param startTime The start time (unix timestamp)
     * @param endTime The end time (unix timestamp)
     */
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
        
        Event storage newEvent = events[eventCount];
        newEvent.id = eventCount;
        newEvent.name = name;
        newEvent.location = location;
        newEvent.startTime = startTime;
        newEvent.endTime = endTime;
        newEvent.isActive = true;
        
        emit EventCreated(eventCount, name, startTime, endTime);
    }
    
    /**
     * @dev Check in to an event
     * @param eventId The ID of the event
     */
    function checkIn(uint256 eventId) external {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        Event storage eventData = events[eventId];
        
        require(eventData.isActive, "Event is not active");
        require(block.timestamp >= eventData.startTime, "Event has not started yet");
        require(block.timestamp <= eventData.endTime, "Event has ended");
        require(!hasCheckedIn[eventId][msg.sender], "Already checked in");
        
        hasCheckedIn[eventId][msg.sender] = true;
        checkInTime[eventId][msg.sender] = block.timestamp;
        eventData.attendees.push(msg.sender);
        
        emit CheckedIn(eventId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Close an event (organizer only)
     * @param eventId The ID of the event
     */
    function closeEvent(uint256 eventId) external onlyOrganizer {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        Event storage eventData = events[eventId];
        
        require(eventData.isActive, "Event is already closed");
        
        eventData.isActive = false;
        
        emit EventClosed(eventId);
    }
    
    /**
     * @dev Get event details
     * @param eventId The ID of the event
     * @return id Event ID
     * @return name Event name
     * @return location Event location
     * @return startTime Start time
     * @return endTime End time
     * @return isActive Whether the event is active
     * @return attendeeCount Number of attendees
     */
    function getEvent(uint256 eventId) external view returns (
        uint256 id,
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 attendeeCount
    ) {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        Event memory eventData = events[eventId];
        
        return (
            eventData.id,
            eventData.name,
            eventData.location,
            eventData.startTime,
            eventData.endTime,
            eventData.isActive,
            eventData.attendees.length
        );
    }
    
    /**
     * @dev Get all attendees for an event
     * @param eventId The ID of the event
     * @return Array of attendee addresses
     */
    function getAttendees(uint256 eventId) external view returns (address[] memory) {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        return events[eventId].attendees;
    }
    
    /**
     * @dev Check if an address has checked in to an event
     * @param eventId The ID of the event
     * @param attendee The address to check
     * @return True if checked in, false otherwise
     */
    function hasAttendeeCheckedIn(uint256 eventId, address attendee) external view returns (bool) {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        return hasCheckedIn[eventId][attendee];
    }
    
    /**
     * @dev Get the check-in time for an attendee
     * @param eventId The ID of the event
     * @param attendee The address to check
     * @return The check-in timestamp (0 if not checked in)
     */
    function getCheckInTime(uint256 eventId, address attendee) external view returns (uint256) {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        return checkInTime[eventId][attendee];
    }
    
    /**
     * @dev Get the attendance count for an event
     * @param eventId The ID of the event
     * @return The number of attendees
     */
    function getAttendanceCount(uint256 eventId) external view returns (uint256) {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        return events[eventId].attendees.length;
    }
    
    /**
     * @dev Get all event IDs
     * @return Array of all event IDs
     */
    function getAllEventIds() external view returns (uint256[] memory) {
        uint256[] memory eventIds = new uint256[](eventCount);
        for (uint256 i = 0; i < eventCount; i++) {
            eventIds[i] = i + 1;
        }
        return eventIds;
    }
    
    /**
     * @dev Get all active event IDs
     * @return Array of active event IDs
     */
    function getActiveEventIds() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active events
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeCount++;
            }
        }
        
        // Collect active event IDs
        uint256[] memory activeEvents = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeEvents[index] = i;
                index++;
            }
        }
        
        return activeEvents;
    }
    
    /**
     * @dev Get all events the caller has attended
     * @return Array of event IDs
     */
    function getMyAttendedEvents() external view returns (uint256[] memory) {
        uint256 attendedCount = 0;
        
        // Count attended events
        for (uint256 i = 1; i <= eventCount; i++) {
            if (hasCheckedIn[i][msg.sender]) {
                attendedCount++;
            }
        }
        
        // Collect attended event IDs
        uint256[] memory attendedEvents = new uint256[](attendedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= eventCount; i++) {
            if (hasCheckedIn[i][msg.sender]) {
                attendedEvents[index] = i;
                index++;
            }
        }
        
        return attendedEvents;
    }
    
    /**
     * @dev Get all events an address has attended
     * @param attendee The address to query
     * @return Array of event IDs
     */
    function getAttendedEventsByAddress(address attendee) external view returns (uint256[] memory) {
        uint256 attendedCount = 0;
        
        // Count attended events
        for (uint256 i = 1; i <= eventCount; i++) {
            if (hasCheckedIn[i][attendee]) {
                attendedCount++;
            }
        }
        
        // Collect attended event IDs
        uint256[] memory attendedEvents = new uint256[](attendedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= eventCount; i++) {
            if (hasCheckedIn[i][attendee]) {
                attendedEvents[index] = i;
                index++;
            }
        }
        
        return attendedEvents;
    }
    
    /**
     * @dev Check if an event is currently open for check-in
     * @param eventId The ID of the event
     * @return True if event is open for check-in, false otherwise
     */
    function isEventOpenForCheckIn(uint256 eventId) external view returns (bool) {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        Event memory eventData = events[eventId];
        
        return eventData.isActive && 
               block.timestamp >= eventData.startTime && 
               block.timestamp <= eventData.endTime;
    }
    
    /**
     * @dev Transfer organizer role to a new address
     * @param newOrganizer The new organizer's address
     */
    function transferOrganizer(address newOrganizer) external onlyOrganizer {
        require(newOrganizer != address(0), "New organizer cannot be zero address");
        require(newOrganizer != organizer, "New organizer is the same as current organizer");
        
        organizer = newOrganizer;
    }
}
