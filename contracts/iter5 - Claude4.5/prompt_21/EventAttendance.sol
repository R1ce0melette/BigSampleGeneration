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
    
    struct Attendee {
        address attendeeAddress;
        uint256 checkInTime;
    }
    
    uint256 public eventCount;
    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => bool)) public hasCheckedIn;
    mapping(uint256 => Attendee[]) public eventAttendees;
    
    event EventCreated(uint256 indexed eventId, string name, uint256 startTime, uint256 endTime);
    event CheckedIn(uint256 indexed eventId, address indexed attendee, uint256 checkInTime);
    event EventClosed(uint256 indexed eventId);
    
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer can call this function");
        _;
    }
    
    constructor() {
        organizer = msg.sender;
    }
    
    function createEvent(
        string memory _name,
        string memory _location,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOrganizer {
        require(bytes(_name).length > 0, "Event name cannot be empty");
        require(bytes(_location).length > 0, "Event location cannot be empty");
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
    
    function checkIn(uint256 _eventId) external {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist");
        
        Event storage eventData = events[_eventId];
        
        require(eventData.isActive, "Event is not active");
        require(block.timestamp >= eventData.startTime, "Event has not started yet");
        require(block.timestamp <= eventData.endTime, "Event has ended");
        require(!hasCheckedIn[_eventId][msg.sender], "Already checked in");
        
        hasCheckedIn[_eventId][msg.sender] = true;
        eventAttendees[_eventId].push(Attendee({
            attendeeAddress: msg.sender,
            checkInTime: block.timestamp
        }));
        
        eventData.attendeeCount++;
        
        emit CheckedIn(_eventId, msg.sender, block.timestamp);
    }
    
    function closeEvent(uint256 _eventId) external onlyOrganizer {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist");
        
        Event storage eventData = events[_eventId];
        require(eventData.isActive, "Event is already closed");
        
        eventData.isActive = false;
        
        emit EventClosed(_eventId);
    }
    
    function isCheckedIn(uint256 _eventId, address _attendee) external view returns (bool) {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist");
        return hasCheckedIn[_eventId][_attendee];
    }
    
    function getEvent(uint256 _eventId) external view returns (
        uint256 id,
        string memory name,
        string memory location,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 attendeeCount
    ) {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist");
        
        Event memory eventData = events[_eventId];
        
        return (
            eventData.id,
            eventData.name,
            eventData.location,
            eventData.startTime,
            eventData.endTime,
            eventData.isActive,
            eventData.attendeeCount
        );
    }
    
    function getEventAttendees(uint256 _eventId) external view returns (Attendee[] memory) {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist");
        return eventAttendees[_eventId];
    }
    
    function getAttendeeCheckInTime(uint256 _eventId, address _attendee) external view returns (uint256) {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist");
        require(hasCheckedIn[_eventId][_attendee], "Attendee has not checked in");
        
        Attendee[] memory attendees = eventAttendees[_eventId];
        
        for (uint256 i = 0; i < attendees.length; i++) {
            if (attendees[i].attendeeAddress == _attendee) {
                return attendees[i].checkInTime;
            }
        }
        
        return 0;
    }
    
    function getAttendeeCount(uint256 _eventId) external view returns (uint256) {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist");
        return events[_eventId].attendeeCount;
    }
    
    function getAllEvents() external view returns (Event[] memory) {
        Event[] memory allEvents = new Event[](eventCount);
        
        for (uint256 i = 1; i <= eventCount; i++) {
            allEvents[i - 1] = events[i];
        }
        
        return allEvents;
    }
    
    function getActiveEvents() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
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
}
