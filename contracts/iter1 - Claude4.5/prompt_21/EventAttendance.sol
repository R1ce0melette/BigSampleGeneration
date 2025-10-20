// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EventAttendance
 * @dev A contract that logs attendance for events where users can check in using their wallet address
 */
contract EventAttendance {
    address public owner;
    
    struct Event {
        uint256 id;
        string name;
        string location;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        address[] attendees;
        mapping(address => bool) hasCheckedIn;
        mapping(address => uint256) checkInTime;
    }
    
    uint256 private eventCounter;
    mapping(uint256 => Event) private events;
    
    event EventCreated(
        uint256 indexed eventId,
        string name,
        uint256 startTime,
        uint256 endTime
    );
    
    event CheckedIn(
        uint256 indexed eventId,
        address indexed attendee,
        uint256 timestamp
    );
    
    event EventUpdated(uint256 indexed eventId);
    event EventClosed(uint256 indexed eventId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new event
     * @param name Event name
     * @param location Event location
     * @param startTime Event start time
     * @param endTime Event end time
     * @return eventId The ID of the created event
     */
    function createEvent(
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(endTime > startTime, "End time must be after start time");
        require(startTime >= block.timestamp, "Start time must be in the future");
        
        eventCounter++;
        uint256 eventId = eventCounter;
        
        Event storage newEvent = events[eventId];
        newEvent.id = eventId;
        newEvent.name = name;
        newEvent.location = location;
        newEvent.startTime = startTime;
        newEvent.endTime = endTime;
        newEvent.isActive = true;
        
        emit EventCreated(eventId, name, startTime, endTime);
        
        return eventId;
    }
    
    /**
     * @dev Check in to an event
     * @param eventId The ID of the event
     */
    function checkIn(uint256 eventId) external {
        Event storage evt = events[eventId];
        
        require(evt.id != 0, "Event does not exist");
        require(evt.isActive, "Event is not active");
        require(block.timestamp >= evt.startTime, "Event has not started yet");
        require(block.timestamp <= evt.endTime, "Event has ended");
        require(!evt.hasCheckedIn[msg.sender], "Already checked in");
        
        evt.hasCheckedIn[msg.sender] = true;
        evt.checkInTime[msg.sender] = block.timestamp;
        evt.attendees.push(msg.sender);
        
        emit CheckedIn(eventId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Owner can check in a user (manual check-in)
     * @param eventId The ID of the event
     * @param attendee The address to check in
     */
    function adminCheckIn(uint256 eventId, address attendee) external onlyOwner {
        Event storage evt = events[eventId];
        
        require(evt.id != 0, "Event does not exist");
        require(evt.isActive, "Event is not active");
        require(attendee != address(0), "Invalid attendee address");
        require(!evt.hasCheckedIn[attendee], "Already checked in");
        
        evt.hasCheckedIn[attendee] = true;
        evt.checkInTime[attendee] = block.timestamp;
        evt.attendees.push(attendee);
        
        emit CheckedIn(eventId, attendee, block.timestamp);
    }
    
    /**
     * @dev Update event details
     * @param eventId The ID of the event
     * @param name New event name
     * @param location New event location
     * @param startTime New start time
     * @param endTime New end time
     */
    function updateEvent(
        uint256 eventId,
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        Event storage evt = events[eventId];
        
        require(evt.id != 0, "Event does not exist");
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(endTime > startTime, "End time must be after start time");
        
        evt.name = name;
        evt.location = location;
        evt.startTime = startTime;
        evt.endTime = endTime;
        
        emit EventUpdated(eventId);
    }
    
    /**
     * @dev Close an event
     * @param eventId The ID of the event
     */
    function closeEvent(uint256 eventId) external onlyOwner {
        Event storage evt = events[eventId];
        
        require(evt.id != 0, "Event does not exist");
        require(evt.isActive, "Event is already closed");
        
        evt.isActive = false;
        
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
     * @return isActive Whether event is active
     * @return attendeeCount Number of attendees
     */
    function getEventDetails(uint256 eventId) external view returns (
        uint256 id,
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 attendeeCount
    ) {
        Event storage evt = events[eventId];
        require(evt.id != 0, "Event does not exist");
        
        return (
            evt.id,
            evt.name,
            evt.location,
            evt.startTime,
            evt.endTime,
            evt.isActive,
            evt.attendees.length
        );
    }
    
    /**
     * @dev Get all attendees for an event
     * @param eventId The ID of the event
     * @return Array of attendee addresses
     */
    function getAttendees(uint256 eventId) external view returns (address[] memory) {
        require(events[eventId].id != 0, "Event does not exist");
        return events[eventId].attendees;
    }
    
    /**
     * @dev Check if an address has checked in to an event
     * @param eventId The ID of the event
     * @param attendee The address to check
     * @return Whether the address has checked in
     */
    function hasCheckedIn(uint256 eventId, address attendee) external view returns (bool) {
        require(events[eventId].id != 0, "Event does not exist");
        return events[eventId].hasCheckedIn[attendee];
    }
    
    /**
     * @dev Get check-in time for an attendee
     * @param eventId The ID of the event
     * @param attendee The address to check
     * @return The check-in timestamp (0 if not checked in)
     */
    function getCheckInTime(uint256 eventId, address attendee) external view returns (uint256) {
        require(events[eventId].id != 0, "Event does not exist");
        return events[eventId].checkInTime[attendee];
    }
    
    /**
     * @dev Get attendance count for an event
     * @param eventId The ID of the event
     * @return The number of attendees
     */
    function getAttendanceCount(uint256 eventId) external view returns (uint256) {
        require(events[eventId].id != 0, "Event does not exist");
        return events[eventId].attendees.length;
    }
    
    /**
     * @dev Get all active events
     * @return Array of active event IDs
     */
    function getActiveEvents() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count active events
        for (uint256 i = 1; i <= eventCounter; i++) {
            if (events[i].isActive) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeEvents = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCounter; i++) {
            if (events[i].isActive) {
                activeEvents[index] = i;
                index++;
            }
        }
        
        return activeEvents;
    }
    
    /**
     * @dev Get all events
     * @return Array of all event IDs
     */
    function getAllEvents() external view returns (uint256[] memory) {
        uint256[] memory allEvents = new uint256[](eventCounter);
        
        for (uint256 i = 0; i < eventCounter; i++) {
            allEvents[i] = i + 1;
        }
        
        return allEvents;
    }
    
    /**
     * @dev Get ongoing events (currently happening)
     * @return Array of ongoing event IDs
     */
    function getOngoingEvents() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count ongoing events
        for (uint256 i = 1; i <= eventCounter; i++) {
            if (events[i].isActive && 
                block.timestamp >= events[i].startTime && 
                block.timestamp <= events[i].endTime) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory ongoingEvents = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCounter; i++) {
            if (events[i].isActive && 
                block.timestamp >= events[i].startTime && 
                block.timestamp <= events[i].endTime) {
                ongoingEvents[index] = i;
                index++;
            }
        }
        
        return ongoingEvents;
    }
    
    /**
     * @dev Get upcoming events
     * @return Array of upcoming event IDs
     */
    function getUpcomingEvents() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count upcoming events
        for (uint256 i = 1; i <= eventCounter; i++) {
            if (events[i].isActive && block.timestamp < events[i].startTime) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory upcomingEvents = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= eventCounter; i++) {
            if (events[i].isActive && block.timestamp < events[i].startTime) {
                upcomingEvents[index] = i;
                index++;
            }
        }
        
        return upcomingEvents;
    }
    
    /**
     * @dev Get total number of events
     * @return The total count
     */
    function getTotalEvents() external view returns (uint256) {
        return eventCounter;
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}
