// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EventAttendance
 * @dev Contract that logs attendance for an event where users can check in using their wallet address
 */
contract EventAttendance {
    // Event structure
    struct Event {
        uint256 id;
        string name;
        string description;
        address organizer;
        uint256 startTime;
        uint256 endTime;
        bool active;
        uint256 maxAttendees;
        uint256 attendeeCount;
        uint256 createdAt;
    }

    // Attendance record
    struct AttendanceRecord {
        uint256 eventId;
        address attendee;
        uint256 checkInTime;
        string notes;
    }

    // Attendee statistics
    struct AttendeeStats {
        uint256 totalEventsAttended;
        uint256 lastCheckInTime;
    }

    // State variables
    address public owner;
    uint256 private eventCounter;
    
    mapping(uint256 => Event) private events;
    mapping(uint256 => mapping(address => bool)) private hasCheckedIn;
    mapping(uint256 => mapping(address => AttendanceRecord)) private attendanceRecords;
    mapping(uint256 => address[]) private eventAttendees;
    mapping(address => uint256[]) private userEvents;
    mapping(address => AttendeeStats) private attendeeStats;
    mapping(address => bool) private authorizedOrganizers;
    
    uint256[] private allEventIds;
    AttendanceRecord[] private allAttendanceRecords;

    // Events
    event EventCreated(uint256 indexed eventId, string name, address indexed organizer, uint256 startTime, uint256 endTime);
    event CheckedIn(uint256 indexed eventId, address indexed attendee, uint256 timestamp);
    event EventActivated(uint256 indexed eventId);
    event EventDeactivated(uint256 indexed eventId);
    event OrganizerAuthorized(address indexed organizer);
    event OrganizerRevoked(address indexed organizer);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner || authorizedOrganizers[msg.sender],
            "Not authorized"
        );
        _;
    }

    modifier eventExists(uint256 eventId) {
        require(eventId > 0 && eventId <= eventCounter, "Event does not exist");
        _;
    }

    modifier onlyEventOrganizer(uint256 eventId) {
        require(events[eventId].organizer == msg.sender, "Not the event organizer");
        _;
    }

    modifier eventActive(uint256 eventId) {
        require(events[eventId].active, "Event is not active");
        _;
    }

    constructor() {
        owner = msg.sender;
        eventCounter = 0;
        authorizedOrganizers[msg.sender] = true;
    }

    /**
     * @dev Create a new event
     * @param name Event name
     * @param description Event description
     * @param startTime Event start time
     * @param endTime Event end time
     * @param maxAttendees Maximum number of attendees (0 for unlimited)
     * @return eventId ID of the created event
     */
    function createEvent(
        string memory name,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        uint256 maxAttendees
    ) public onlyAuthorized returns (uint256) {
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(endTime > startTime, "End time must be after start time");
        require(startTime >= block.timestamp, "Start time must be in the future");

        eventCounter++;
        uint256 eventId = eventCounter;

        Event storage newEvent = events[eventId];
        newEvent.id = eventId;
        newEvent.name = name;
        newEvent.description = description;
        newEvent.organizer = msg.sender;
        newEvent.startTime = startTime;
        newEvent.endTime = endTime;
        newEvent.active = true;
        newEvent.maxAttendees = maxAttendees;
        newEvent.attendeeCount = 0;
        newEvent.createdAt = block.timestamp;

        allEventIds.push(eventId);

        emit EventCreated(eventId, name, msg.sender, startTime, endTime);

        return eventId;
    }

    /**
     * @dev Check in to an event
     * @param eventId Event ID
     * @param notes Optional check-in notes
     */
    function checkIn(uint256 eventId, string memory notes) 
        public 
        eventExists(eventId)
        eventActive(eventId)
    {
        Event storage eventData = events[eventId];
        
        require(block.timestamp >= eventData.startTime, "Event has not started yet");
        require(block.timestamp <= eventData.endTime, "Event has ended");
        require(!hasCheckedIn[eventId][msg.sender], "Already checked in");
        
        if (eventData.maxAttendees > 0) {
            require(eventData.attendeeCount < eventData.maxAttendees, "Event is at maximum capacity");
        }

        // Record attendance
        AttendanceRecord memory record = AttendanceRecord({
            eventId: eventId,
            attendee: msg.sender,
            checkInTime: block.timestamp,
            notes: notes
        });

        attendanceRecords[eventId][msg.sender] = record;
        hasCheckedIn[eventId][msg.sender] = true;
        eventAttendees[eventId].push(msg.sender);
        userEvents[msg.sender].push(eventId);
        allAttendanceRecords.push(record);

        eventData.attendeeCount++;

        // Update attendee stats
        AttendeeStats storage stats = attendeeStats[msg.sender];
        stats.totalEventsAttended++;
        stats.lastCheckInTime = block.timestamp;

        emit CheckedIn(eventId, msg.sender, block.timestamp);
    }

    /**
     * @dev Check in to an event without notes
     * @param eventId Event ID
     */
    function checkIn(uint256 eventId) public {
        checkIn(eventId, "");
    }

    /**
     * @dev Activate an event
     * @param eventId Event ID
     */
    function activateEvent(uint256 eventId) 
        public 
        eventExists(eventId)
        onlyEventOrganizer(eventId)
    {
        require(!events[eventId].active, "Event is already active");
        events[eventId].active = true;
        emit EventActivated(eventId);
    }

    /**
     * @dev Deactivate an event
     * @param eventId Event ID
     */
    function deactivateEvent(uint256 eventId) 
        public 
        eventExists(eventId)
        onlyEventOrganizer(eventId)
    {
        require(events[eventId].active, "Event is already inactive");
        events[eventId].active = false;
        emit EventDeactivated(eventId);
    }

    /**
     * @dev Update event details
     * @param eventId Event ID
     * @param name New event name
     * @param description New event description
     * @param startTime New start time
     * @param endTime New end time
     */
    function updateEvent(
        uint256 eventId,
        string memory name,
        string memory description,
        uint256 startTime,
        uint256 endTime
    ) public eventExists(eventId) onlyEventOrganizer(eventId) {
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(endTime > startTime, "End time must be after start time");

        Event storage eventData = events[eventId];
        eventData.name = name;
        eventData.description = description;
        eventData.startTime = startTime;
        eventData.endTime = endTime;
    }

    /**
     * @dev Get event details
     * @param eventId Event ID
     * @return Event details
     */
    function getEvent(uint256 eventId) 
        public 
        view 
        eventExists(eventId)
        returns (Event memory) 
    {
        return events[eventId];
    }

    /**
     * @dev Get attendance record
     * @param eventId Event ID
     * @param attendee Attendee address
     * @return AttendanceRecord details
     */
    function getAttendanceRecord(uint256 eventId, address attendee) 
        public 
        view 
        eventExists(eventId)
        returns (AttendanceRecord memory) 
    {
        require(hasCheckedIn[eventId][attendee], "Attendee has not checked in");
        return attendanceRecords[eventId][attendee];
    }

    /**
     * @dev Check if user has checked in to an event
     * @param eventId Event ID
     * @param attendee Attendee address
     * @return true if checked in
     */
    function hasUserCheckedIn(uint256 eventId, address attendee) 
        public 
        view 
        eventExists(eventId)
        returns (bool) 
    {
        return hasCheckedIn[eventId][attendee];
    }

    /**
     * @dev Get all events
     * @return Array of all events
     */
    function getAllEvents() public view returns (Event[] memory) {
        Event[] memory allEvents = new Event[](allEventIds.length);
        
        for (uint256 i = 0; i < allEventIds.length; i++) {
            allEvents[i] = events[allEventIds[i]];
        }
        
        return allEvents;
    }

    /**
     * @dev Get active events
     * @return Array of active events
     */
    function getActiveEvents() public view returns (Event[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allEventIds.length; i++) {
            if (events[allEventIds[i]].active) {
                count++;
            }
        }

        Event[] memory result = new Event[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allEventIds.length; i++) {
            Event memory eventData = events[allEventIds[i]];
            if (eventData.active) {
                result[index] = eventData;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get upcoming events
     * @return Array of upcoming events
     */
    function getUpcomingEvents() public view returns (Event[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allEventIds.length; i++) {
            Event memory eventData = events[allEventIds[i]];
            if (eventData.active && eventData.startTime > block.timestamp) {
                count++;
            }
        }

        Event[] memory result = new Event[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allEventIds.length; i++) {
            Event memory eventData = events[allEventIds[i]];
            if (eventData.active && eventData.startTime > block.timestamp) {
                result[index] = eventData;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get ongoing events
     * @return Array of ongoing events
     */
    function getOngoingEvents() public view returns (Event[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allEventIds.length; i++) {
            Event memory eventData = events[allEventIds[i]];
            if (eventData.active && 
                eventData.startTime <= block.timestamp && 
                eventData.endTime >= block.timestamp) {
                count++;
            }
        }

        Event[] memory result = new Event[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allEventIds.length; i++) {
            Event memory eventData = events[allEventIds[i]];
            if (eventData.active && 
                eventData.startTime <= block.timestamp && 
                eventData.endTime >= block.timestamp) {
                result[index] = eventData;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get event attendees
     * @param eventId Event ID
     * @return Array of attendee addresses
     */
    function getEventAttendees(uint256 eventId) 
        public 
        view 
        eventExists(eventId)
        returns (address[] memory) 
    {
        return eventAttendees[eventId];
    }

    /**
     * @dev Get event attendance records
     * @param eventId Event ID
     * @return Array of attendance records
     */
    function getEventAttendanceRecords(uint256 eventId) 
        public 
        view 
        eventExists(eventId)
        returns (AttendanceRecord[] memory) 
    {
        address[] memory attendees = eventAttendees[eventId];
        AttendanceRecord[] memory records = new AttendanceRecord[](attendees.length);

        for (uint256 i = 0; i < attendees.length; i++) {
            records[i] = attendanceRecords[eventId][attendees[i]];
        }

        return records;
    }

    /**
     * @dev Get user's attended events
     * @param user User address
     * @return Array of event IDs
     */
    function getUserEvents(address user) public view returns (uint256[] memory) {
        return userEvents[user];
    }

    /**
     * @dev Get user's attended event details
     * @param user User address
     * @return Array of events
     */
    function getUserEventDetails(address user) public view returns (Event[] memory) {
        uint256[] memory eventIds = userEvents[user];
        Event[] memory result = new Event[](eventIds.length);

        for (uint256 i = 0; i < eventIds.length; i++) {
            result[i] = events[eventIds[i]];
        }

        return result;
    }

    /**
     * @dev Get user's attendance records
     * @param user User address
     * @return Array of attendance records
     */
    function getUserAttendanceRecords(address user) public view returns (AttendanceRecord[] memory) {
        uint256[] memory eventIds = userEvents[user];
        AttendanceRecord[] memory records = new AttendanceRecord[](eventIds.length);

        for (uint256 i = 0; i < eventIds.length; i++) {
            records[i] = attendanceRecords[eventIds[i]][user];
        }

        return records;
    }

    /**
     * @dev Get attendee statistics
     * @param attendee Attendee address
     * @return AttendeeStats structure
     */
    function getAttendeeStats(address attendee) public view returns (AttendeeStats memory) {
        return attendeeStats[attendee];
    }

    /**
     * @dev Get all attendance records
     * @return Array of all attendance records
     */
    function getAllAttendanceRecords() public view returns (AttendanceRecord[] memory) {
        return allAttendanceRecords;
    }

    /**
     * @dev Get events by organizer
     * @param organizer Organizer address
     * @return Array of events
     */
    function getEventsByOrganizer(address organizer) public view returns (Event[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allEventIds.length; i++) {
            if (events[allEventIds[i]].organizer == organizer) {
                count++;
            }
        }

        Event[] memory result = new Event[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allEventIds.length; i++) {
            Event memory eventData = events[allEventIds[i]];
            if (eventData.organizer == organizer) {
                result[index] = eventData;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total event count
     * @return Total number of events
     */
    function getTotalEventCount() public view returns (uint256) {
        return eventCounter;
    }

    /**
     * @dev Get event attendee count
     * @param eventId Event ID
     * @return Number of attendees
     */
    function getEventAttendeeCount(uint256 eventId) 
        public 
        view 
        eventExists(eventId)
        returns (uint256) 
    {
        return events[eventId].attendeeCount;
    }

    /**
     * @dev Get total attendance count across all events
     * @return Total attendance count
     */
    function getTotalAttendanceCount() public view returns (uint256) {
        return allAttendanceRecords.length;
    }

    /**
     * @dev Authorize an organizer
     * @param organizer Organizer address
     */
    function authorizeOrganizer(address organizer) public onlyOwner {
        require(organizer != address(0), "Invalid organizer address");
        require(!authorizedOrganizers[organizer], "Already authorized");

        authorizedOrganizers[organizer] = true;

        emit OrganizerAuthorized(organizer);
    }

    /**
     * @dev Revoke organizer authorization
     * @param organizer Organizer address
     */
    function revokeOrganizer(address organizer) public onlyOwner {
        require(organizer != owner, "Cannot revoke owner");
        require(authorizedOrganizers[organizer], "Not authorized");

        authorizedOrganizers[organizer] = false;

        emit OrganizerRevoked(organizer);
    }

    /**
     * @dev Check if address is authorized organizer
     * @param organizer Address to check
     * @return true if authorized
     */
    function isAuthorizedOrganizer(address organizer) public view returns (bool) {
        return authorizedOrganizers[organizer];
    }

    /**
     * @dev Get recent events
     * @param count Number of recent events to retrieve
     * @return Array of recent events
     */
    function getRecentEvents(uint256 count) public view returns (Event[] memory) {
        uint256 totalCount = allEventIds.length;
        uint256 resultCount = count > totalCount ? totalCount : count;

        Event[] memory result = new Event[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = events[allEventIds[totalCount - 1 - i]];
        }

        return result;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");

        authorizedOrganizers[owner] = false;
        owner = newOwner;
        authorizedOrganizers[newOwner] = true;
    }
}
