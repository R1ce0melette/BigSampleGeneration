// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AttendanceLogger
 * @dev A contract that logs attendance for events where users can check in using their wallet address
 */
contract AttendanceLogger {
    address public eventOrganizer;
    
    struct Event {
        uint256 id;
        string name;
        string location;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 attendeeCount;
    }
    
    struct AttendanceRecord {
        address attendee;
        uint256 checkInTime;
        bool hasCheckedIn;
    }
    
    uint256 public eventCount;
    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => AttendanceRecord)) public attendance;
    mapping(uint256 => address[]) public eventAttendees;
    
    // Events
    event EventCreated(uint256 indexed eventId, string name, uint256 startTime, uint256 endTime);
    event CheckedIn(uint256 indexed eventId, address indexed attendee, uint256 timestamp);
    event EventActivated(uint256 indexed eventId);
    event EventDeactivated(uint256 indexed eventId);
    
    modifier onlyOrganizer() {
        require(msg.sender == eventOrganizer, "Only organizer can call this function");
        _;
    }
    
    constructor() {
        eventOrganizer = msg.sender;
    }
    
    /**
     * @dev Creates a new event
     * @param _name The name of the event
     * @param _location The location of the event
     * @param _startTime The start time of the event
     * @param _endTime The end time of the event
     */
    function createEvent(
        string memory _name,
        string memory _location,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOrganizer {
        require(bytes(_name).length > 0, "Event name cannot be empty");
        require(_startTime < _endTime, "Start time must be before end time");
        require(_endTime > block.timestamp, "End time must be in the future");
        
        eventCount++;
        
        events[eventCount] = Event({
            id: eventCount,
            name: _name,
            location: _location,
            startTime: _startTime,
            endTime: _endTime,
            isActive: true,
            attendeeCount: 0
        });
        
        emit EventCreated(eventCount, _name, _startTime, _endTime);
    }
    
    /**
     * @dev Allows a user to check in to an event
     * @param _eventId The ID of the event
     */
    function checkIn(uint256 _eventId) external {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        Event storage evt = events[_eventId];
        
        require(evt.isActive, "Event is not active");
        require(block.timestamp >= evt.startTime, "Event has not started yet");
        require(block.timestamp <= evt.endTime, "Event has ended");
        require(!attendance[_eventId][msg.sender].hasCheckedIn, "Already checked in");
        
        attendance[_eventId][msg.sender] = AttendanceRecord({
            attendee: msg.sender,
            checkInTime: block.timestamp,
            hasCheckedIn: true
        });
        
        eventAttendees[_eventId].push(msg.sender);
        evt.attendeeCount++;
        
        emit CheckedIn(_eventId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Activates an event for check-ins
     * @param _eventId The ID of the event
     */
    function activateEvent(uint256 _eventId) external onlyOrganizer {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        require(!events[_eventId].isActive, "Event is already active");
        
        events[_eventId].isActive = true;
        
        emit EventActivated(_eventId);
    }
    
    /**
     * @dev Deactivates an event to prevent further check-ins
     * @param _eventId The ID of the event
     */
    function deactivateEvent(uint256 _eventId) external onlyOrganizer {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        require(events[_eventId].isActive, "Event is already inactive");
        
        events[_eventId].isActive = false;
        
        emit EventDeactivated(_eventId);
    }
    
    /**
     * @dev Returns the details of an event
     * @param _eventId The ID of the event
     * @return id The event ID
     * @return name The event name
     * @return location The event location
     * @return startTime The start time
     * @return endTime The end time
     * @return isActive Whether the event is active
     * @return attendeeCount The number of attendees
     */
    function getEvent(uint256 _eventId) external view returns (
        uint256 id,
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 attendeeCount
    ) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        Event memory evt = events[_eventId];
        
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
     * @dev Returns the attendance record for a user at an event
     * @param _eventId The ID of the event
     * @param _attendee The address of the attendee
     * @return attendee The attendee's address
     * @return checkInTime When they checked in
     * @return hasCheckedIn Whether they have checked in
     */
    function getAttendanceRecord(uint256 _eventId, address _attendee) external view returns (
        address attendee,
        uint256 checkInTime,
        bool hasCheckedIn
    ) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        AttendanceRecord memory record = attendance[_eventId][_attendee];
        
        return (
            record.attendee,
            record.checkInTime,
            record.hasCheckedIn
        );
    }
    
    /**
     * @dev Checks if a user has checked in to an event
     * @param _eventId The ID of the event
     * @param _attendee The address of the attendee
     * @return True if checked in, false otherwise
     */
    function hasCheckedIn(uint256 _eventId, address _attendee) external view returns (bool) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        return attendance[_eventId][_attendee].hasCheckedIn;
    }
    
    /**
     * @dev Checks if the caller has checked in to an event
     * @param _eventId The ID of the event
     * @return True if checked in, false otherwise
     */
    function haveICheckedIn(uint256 _eventId) external view returns (bool) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        return attendance[_eventId][msg.sender].hasCheckedIn;
    }
    
    /**
     * @dev Returns all attendees for an event
     * @param _eventId The ID of the event
     * @return Array of attendee addresses
     */
    function getEventAttendees(uint256 _eventId) external view returns (address[] memory) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        return eventAttendees[_eventId];
    }
    
    /**
     * @dev Returns the number of attendees for an event
     * @param _eventId The ID of the event
     * @return The attendee count
     */
    function getAttendeeCount(uint256 _eventId) external view returns (uint256) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        return events[_eventId].attendeeCount;
    }
    
    /**
     * @dev Returns all events
     * @return Array of all events
     */
    function getAllEvents() external view returns (Event[] memory) {
        Event[] memory allEvents = new Event[](eventCount);
        
        for (uint256 i = 1; i <= eventCount; i++) {
            allEvents[i - 1] = events[i];
        }
        
        return allEvents;
    }
    
    /**
     * @dev Returns all active events
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
        
        // Create array of active event IDs
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
     * @dev Returns upcoming events (events that haven't ended yet)
     * @return Array of upcoming event IDs
     */
    function getUpcomingEvents() external view returns (uint256[] memory) {
        uint256 upcomingCount = 0;
        
        // Count upcoming events
        for (uint256 i = 1; i <= eventCount; i++) {
            if (block.timestamp < events[i].endTime) {
                upcomingCount++;
            }
        }
        
        // Create array of upcoming event IDs
        uint256[] memory upcomingEvents = new uint256[](upcomingCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (block.timestamp < events[i].endTime) {
                upcomingEvents[index] = i;
                index++;
            }
        }
        
        return upcomingEvents;
    }
    
    /**
     * @dev Returns events the caller has attended
     * @return Array of event IDs
     */
    function getMyAttendedEvents() external view returns (uint256[] memory) {
        uint256 attendedCount = 0;
        
        // Count attended events
        for (uint256 i = 1; i <= eventCount; i++) {
            if (attendance[i][msg.sender].hasCheckedIn) {
                attendedCount++;
            }
        }
        
        // Create array of attended event IDs
        uint256[] memory attendedEvents = new uint256[](attendedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (attendance[i][msg.sender].hasCheckedIn) {
                attendedEvents[index] = i;
                index++;
            }
        }
        
        return attendedEvents;
    }
    
    /**
     * @dev Returns the total number of events
     * @return The event count
     */
    function getTotalEvents() external view returns (uint256) {
        return eventCount;
    }
    
    /**
     * @dev Transfers organizer role to a new address
     * @param _newOrganizer The address of the new organizer
     */
    function transferOrganizer(address _newOrganizer) external onlyOrganizer {
        require(_newOrganizer != address(0), "New organizer cannot be zero address");
        require(_newOrganizer != eventOrganizer, "New organizer must be different");
        
        eventOrganizer = _newOrganizer;
    }
}
