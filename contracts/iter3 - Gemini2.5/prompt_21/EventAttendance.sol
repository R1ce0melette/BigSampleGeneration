// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventAttendance
 * @dev A contract to log attendance for an event. Users can check in
 * with their wallet address, and the event organizer can manage the event.
 */
contract EventAttendance {
    address public organizer;
    string public eventName;
    bool public isCheckInActive;

    // Mapping to track which addresses have checked in
    mapping(address => bool) public hasCheckedIn;
    // Array to store the addresses of all attendees
    address[] public attendees;

    /**
     * @dev Emitted when the check-in for an event is opened.
     * @param eventName The name of the event.
     */
    event CheckInOpened(string eventName);

    /**
     * @dev Emitted when the check-in for an event is closed.
     */
    event CheckInClosed();

    /**
     * @dev Emitted when a user successfully checks in.
     * @param attendee The address of the user who checked in.
     */
    event UserCheckedIn(address indexed attendee);

    /**
     * @dev Modifier to restrict certain functions to the event organizer.
     */
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only the organizer can perform this action.");
        _;
    }

    /**
     * @dev Sets up the contract with the event organizer's address.
     */
    constructor() {
        organizer = msg.sender;
        isCheckInActive = false;
    }

    /**
     * @dev Opens the check-in for an event.
     * Only the organizer can call this function.
     * @param _eventName The name of the event.
     */
    function openCheckIn(string memory _eventName) public onlyOrganizer {
        require(!isCheckInActive, "Check-in is already active.");
        require(bytes(_eventName).length > 0, "Event name cannot be empty.");

        eventName = _eventName;
        isCheckInActive = true;
        
        // Reset previous event data
        delete attendees;
        // Note: `hasCheckedIn` mapping is not reset here to prevent re-check-ins
        // across different events if desired. For a per-event check, a more
        // complex structure would be needed (e.g., mapping eventId to attendance).

        emit CheckInOpened(_eventName);
    }

    /**
     * @dev Allows a user to check in for the event.
     * A user can only check in once.
     */
    function checkIn() public {
        require(isCheckInActive, "Check-in is not currently active.");
        require(!hasCheckedIn[msg.sender], "You have already checked in.");

        hasCheckedIn[msg.sender] = true;
        attendees.push(msg.sender);

        emit UserCheckedIn(msg.sender);
    }

    /**
     * @dev Closes the check-in for the event.
     * Only the organizer can call this function.
     */
    function closeCheckIn() public onlyOrganizer {
        require(isCheckInActive, "Check-in is not currently active.");
        isCheckInActive = false;
        emit CheckInClosed();
    }

    /**
     * @dev Retrieves the list of all attendees who have checked in.
     * @return An array of attendee addresses.
     */
    function getAttendees() public view returns (address[] memory) {
        return attendees;
    }

    /**
     * @dev Returns the total number of attendees who have checked in.
     * @return The count of attendees.
     */
    function getAttendeeCount() public view returns (uint256) {
        return attendees.length;
    }

    /**
     * @dev Checks if a specific user has checked in for the event.
     * @param _user The address of the user to check.
     * @return True if the user has checked in, false otherwise.
     */
    function didUserCheckIn(address _user) public view returns (bool) {
        return hasCheckedIn[_user];
    }

    /**
     * @dev Allows the organizer to transfer their role to a new address.
     * @param _newOrganizer The address of the new organizer.
     */
    function transferOrganizership(address _newOrganizer) public onlyOrganizer {
        require(_newOrganizer != address(0), "New organizer cannot be the zero address.");
        organizer = _newOrganizer;
    }
}
