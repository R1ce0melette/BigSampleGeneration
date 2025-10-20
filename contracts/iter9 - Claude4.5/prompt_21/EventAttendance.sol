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
        bool isActive;
        uint256 attendeeCount;
    }
    
    struct AttendanceRecord {
        address attendee;
        uint256 checkInTime;
        bool checkedIn;
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
        require(msg.sender == organizer, "Only organizer can call this function");
        _;
    }
    
    constructor() {
        organizer = msg.sender;
    }
    
    /**
     * @dev Create a new event
     * @param _name The event name
     * @param _location The event location
     * @param _startTime The event start timestamp
     * @param _endTime The event end timestamp
     */
    function createEvent(
        string memory _name,
        string memory _location,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOrganizer {
        require(bytes(_name).length > 0, "Event name cannot be empty");
        require(_endTime > _startTime, "End time must be after start time");
        require(_startTime >= block.timestamp, "Start time must be in the future");
        
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
     * @dev Check in to an event
     * @param _eventId The ID of the event
     */
    function checkIn(uint256 _eventId) external {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        Event storage evt = events[_eventId];
        
        require(evt.isActive, "Event is not active");
        require(block.timestamp >= evt.startTime, "Event has not started yet");
        require(block.timestamp <= evt.endTime, "Event has ended");
        require(!attendance[_eventId][msg.sender].checkedIn, "Already checked in");
        
        attendance[_eventId][msg.sender] = AttendanceRecord({
            attendee: msg.sender,
            checkInTime: block.timestamp,
            checkedIn: true
        });
        
        eventAttendees[_eventId].push(msg.sender);
        evt.attendeeCount++;
        
        emit CheckedIn(_eventId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Organizer can check in a user manually
     * @param _eventId The ID of the event
     * @param _attendee The address of the attendee
     */
    function checkInAttendee(uint256 _eventId, address _attendee) external onlyOrganizer {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        require(_attendee != address(0), "Invalid attendee address");
        
        Event storage evt = events[_eventId];
        
        require(evt.isActive, "Event is not active");
        require(!attendance[_eventId][_attendee].checkedIn, "Already checked in");
        
        attendance[_eventId][_attendee] = AttendanceRecord({
            attendee: _attendee,
            checkInTime: block.timestamp,
            checkedIn: true
        });
        
        eventAttendees[_eventId].push(_attendee);
        evt.attendeeCount++;
        
        emit CheckedIn(_eventId, _attendee, block.timestamp);
    }
    
    /**
     * @dev Activate an event
     * @param _eventId The ID of the event
     */
    function activateEvent(uint256 _eventId) external onlyOrganizer {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        require(!events[_eventId].isActive, "Event is already active");
        
        events[_eventId].isActive = true;
        
        emit EventActivated(_eventId);
    }
    
    /**
     * @dev Deactivate an event
     * @param _eventId The ID of the event
     */
    function deactivateEvent(uint256 _eventId) external onlyOrganizer {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        require(events[_eventId].isActive, "Event is already inactive");
        
        events[_eventId].isActive = false;
        
        emit EventDeactivated(_eventId);
    }
    
    /**
     * @dev Check if a user has checked in to an event
     * @param _eventId The ID of the event
     * @param _attendee The address of the attendee
     * @return True if checked in, false otherwise
     */
    function hasCheckedIn(uint256 _eventId, address _attendee) external view returns (bool) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        return attendance[_eventId][_attendee].checkedIn;
    }
    
    /**
     * @dev Get event details
     * @param _eventId The ID of the event
     * @return id The event ID
     * @return name The event name
     * @return location The event location
     * @return startTime The start timestamp
     * @return endTime The end timestamp
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
     * @dev Get attendance record for a user
     * @param _eventId The ID of the event
     * @param _attendee The address of the attendee
     * @return attendee The attendee address
     * @return checkInTime The check-in timestamp
     * @return checkedIn Whether the user checked in
     */
    function getAttendanceRecord(uint256 _eventId, address _attendee) external view returns (
        address attendee,
        uint256 checkInTime,
        bool checkedIn
    ) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        AttendanceRecord memory record = attendance[_eventId][_attendee];
        
        return (
            record.attendee,
            record.checkInTime,
            record.checkedIn
        );
    }
    
    /**
     * @dev Get all attendees for an event
     * @param _eventId The ID of the event
     * @return Array of attendee addresses
     */
    function getEventAttendees(uint256 _eventId) external view returns (address[] memory) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        return eventAttendees[_eventId];
    }
    
    /**
     * @dev Get attendee count for an event
     * @param _eventId The ID of the event
     * @return The number of attendees
     */
    function getAttendeeCount(uint256 _eventId) external view returns (uint256) {
        require(_eventId > 0 && _eventId <= eventCount, "Invalid event ID");
        
        return events[_eventId].attendeeCount;
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
     * @dev Transfer organizer role to a new address
     * @param _newOrganizer The new organizer address
     */
    function transferOrganizer(address _newOrganizer) external onlyOrganizer {
        require(_newOrganizer != address(0), "Invalid organizer address");
        
        organizer = _newOrganizer;
    }
}
