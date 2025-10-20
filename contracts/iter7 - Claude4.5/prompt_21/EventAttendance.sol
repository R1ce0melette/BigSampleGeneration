// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EventAttendance
 * @dev A contract that logs attendance for an event where users can check in using their wallet address
 */
contract EventAttendance {
    address public eventOrganizer;
    
    // Event structure
    struct Event {
        uint256 id;
        string name;
        string location;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 attendeeCount;
    }
    
    // Attendance record structure
    struct AttendanceRecord {
        address attendee;
        uint256 checkInTime;
        bool hasCheckedIn;
    }
    
    // State variables
    uint256 public eventCount;
    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => AttendanceRecord)) public eventAttendance;
    mapping(uint256 => address[]) public eventAttendeeList;
    
    // Events
    event EventCreated(uint256 indexed eventId, string name, uint256 startTime, uint256 endTime);
    event CheckedIn(uint256 indexed eventId, address indexed attendee, uint256 timestamp);
    event EventActivated(uint256 indexed eventId);
    event EventDeactivated(uint256 indexed eventId);
    
    // Modifiers
    modifier onlyOrganizer() {
        require(msg.sender == eventOrganizer, "Only event organizer can perform this action");
        _;
    }
    
    modifier eventExists(uint256 eventId) {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        _;
    }
    
    /**
     * @dev Constructor sets the event organizer
     */
    constructor() {
        eventOrganizer = msg.sender;
    }
    
    /**
     * @dev Create a new event
     * @param name The event name
     * @param location The event location
     * @param startTime The event start time (unix timestamp)
     * @param endTime The event end time (unix timestamp)
     * @return eventId The ID of the created event
     */
    function createEvent(
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime
    ) external onlyOrganizer returns (uint256) {
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(endTime > startTime, "End time must be after start time");
        require(startTime >= block.timestamp, "Start time cannot be in the past");
        
        eventCount++;
        uint256 eventId = eventCount;
        
        events[eventId] = Event({
            id: eventId,
            name: name,
            location: location,
            startTime: startTime,
            endTime: endTime,
            isActive: true,
            attendeeCount: 0
        });
        
        emit EventCreated(eventId, name, startTime, endTime);
        
        return eventId;
    }
    
    /**
     * @dev Check in to an event
     * @param eventId The ID of the event to check in to
     */
    function checkIn(uint256 eventId) external eventExists(eventId) {
        Event storage evt = events[eventId];
        
        require(evt.isActive, "Event is not active");
        require(block.timestamp >= evt.startTime, "Event has not started yet");
        require(block.timestamp <= evt.endTime, "Event has ended");
        require(!eventAttendance[eventId][msg.sender].hasCheckedIn, "Already checked in to this event");
        
        eventAttendance[eventId][msg.sender] = AttendanceRecord({
            attendee: msg.sender,
            checkInTime: block.timestamp,
            hasCheckedIn: true
        });
        
        eventAttendeeList[eventId].push(msg.sender);
        events[eventId].attendeeCount++;
        
        emit CheckedIn(eventId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Organizer can check in an attendee on their behalf
     * @param eventId The ID of the event
     * @param attendee The address of the attendee
     */
    function checkInAttendee(uint256 eventId, address attendee) external onlyOrganizer eventExists(eventId) {
        Event storage evt = events[eventId];
        
        require(evt.isActive, "Event is not active");
        require(attendee != address(0), "Invalid attendee address");
        require(!eventAttendance[eventId][attendee].hasCheckedIn, "Attendee already checked in");
        
        eventAttendance[eventId][attendee] = AttendanceRecord({
            attendee: attendee,
            checkInTime: block.timestamp,
            hasCheckedIn: true
        });
        
        eventAttendeeList[eventId].push(attendee);
        events[eventId].attendeeCount++;
        
        emit CheckedIn(eventId, attendee, block.timestamp);
    }
    
    /**
     * @dev Check if an address has checked in to an event
     * @param eventId The ID of the event
     * @param attendee The address to check
     * @return True if the address has checked in, false otherwise
     */
    function hasCheckedIn(uint256 eventId, address attendee) external view eventExists(eventId) returns (bool) {
        return eventAttendance[eventId][attendee].hasCheckedIn;
    }
    
    /**
     * @dev Get attendance record for an address
     * @param eventId The ID of the event
     * @param attendee The address to query
     * @return attendeeAddress The attendee's address
     * @return checkInTime The check-in timestamp
     * @return checkedIn Whether they have checked in
     */
    function getAttendanceRecord(uint256 eventId, address attendee) external view eventExists(eventId) returns (
        address attendeeAddress,
        uint256 checkInTime,
        bool checkedIn
    ) {
        AttendanceRecord memory record = eventAttendance[eventId][attendee];
        return (
            record.attendee,
            record.checkInTime,
            record.hasCheckedIn
        );
    }
    
    /**
     * @dev Get all attendees for an event
     * @param eventId The ID of the event
     * @return Array of attendee addresses
     */
    function getEventAttendees(uint256 eventId) external view eventExists(eventId) returns (address[] memory) {
        return eventAttendeeList[eventId];
    }
    
    /**
     * @dev Get event details
     * @param eventId The ID of the event
     * @return id Event ID
     * @return name Event name
     * @return location Event location
     * @return startTime Start time
     * @return endTime End time
     * @return isActive Whether event is active
     * @return attendeeCount Number of attendees
     */
    function getEvent(uint256 eventId) external view eventExists(eventId) returns (
        uint256 id,
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 attendeeCount
    ) {
        Event memory evt = events[eventId];
        return (
            evt.id,
            evt.name,
            evt.location,
            evt.startTime,
            evt.endTime,
            evt.isActive,
            evt.attendeeCount
        );
    }
    
    /**
     * @dev Get attendance count for an event
     * @param eventId The ID of the event
     * @return The number of attendees
     */
    function getAttendanceCount(uint256 eventId) external view eventExists(eventId) returns (uint256) {
        return events[eventId].attendeeCount;
    }
    
    /**
     * @dev Activate an event
     * @param eventId The ID of the event
     */
    function activateEvent(uint256 eventId) external onlyOrganizer eventExists(eventId) {
        require(!events[eventId].isActive, "Event is already active");
        
        events[eventId].isActive = true;
        
        emit EventActivated(eventId);
    }
    
    /**
     * @dev Deactivate an event
     * @param eventId The ID of the event
     */
    function deactivateEvent(uint256 eventId) external onlyOrganizer eventExists(eventId) {
        require(events[eventId].isActive, "Event is already inactive");
        
        events[eventId].isActive = false;
        
        emit EventDeactivated(eventId);
    }
    
    /**
     * @dev Get all events
     * @return Array of event IDs
     */
    function getAllEvents() external view returns (uint256[] memory) {
        uint256[] memory allEventIds = new uint256[](eventCount);
        
        for (uint256 i = 1; i <= eventCount; i++) {
            allEventIds[i - 1] = i;
        }
        
        return allEventIds;
    }
    
    /**
     * @dev Get active events
     * @return Array of active event IDs
     */
    function getActiveEvents() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active events
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeCount++;
            }
        }
        
        // Create array
        uint256[] memory activeEventIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeEventIds[index] = i;
                index++;
            }
        }
        
        return activeEventIds;
    }
    
    /**
     * @dev Get events the caller has checked in to
     * @return Array of event IDs
     */
    function getMyAttendedEvents() external view returns (uint256[] memory) {
        uint256 attendedCount = 0;
        
        // Count attended events
        for (uint256 i = 1; i <= eventCount; i++) {
            if (eventAttendance[i][msg.sender].hasCheckedIn) {
                attendedCount++;
            }
        }
        
        // Create array
        uint256[] memory attendedEventIds = new uint256[](attendedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (eventAttendance[i][msg.sender].hasCheckedIn) {
                attendedEventIds[index] = i;
                index++;
            }
        }
        
        return attendedEventIds;
    }
    
    /**
     * @dev Check if an event is currently ongoing
     * @param eventId The ID of the event
     * @return True if event is ongoing, false otherwise
     */
    function isEventOngoing(uint256 eventId) external view eventExists(eventId) returns (bool) {
        Event memory evt = events[eventId];
        return evt.isActive && block.timestamp >= evt.startTime && block.timestamp <= evt.endTime;
    }
    
    /**
     * @dev Check if caller has checked in to a specific event
     * @param eventId The ID of the event
     * @return True if caller has checked in, false otherwise
     */
    function haveICheckedIn(uint256 eventId) external view eventExists(eventId) returns (bool) {
        return eventAttendance[eventId][msg.sender].hasCheckedIn;
    }
    
    /**
     * @dev Transfer organizer role
     * @param newOrganizer The address of the new organizer
     */
    function transferOrganizer(address newOrganizer) external onlyOrganizer {
        require(newOrganizer != address(0), "Invalid organizer address");
        require(newOrganizer != eventOrganizer, "New organizer is the same as current");
        
        eventOrganizer = newOrganizer;
    }
}
