// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventAttendance
 * @dev A contract to log attendance for an event. Users can check in with their wallet address.
 */
contract EventAttendance {
    address public owner;
    bool public isCheckInOpen;

    // Mapping from an attendee's address to their check-in timestamp
    mapping(address => uint256) public attendees;
    address[] public attendeeList;

    event CheckedIn(address indexed attendee, uint256 timestamp);
    event CheckInOpened();
    event CheckInClosed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isCheckInOpen = true; // By default, check-in is open upon deployment
    }

    /**
     * @dev Allows a user to check in to the event.
     * A user can only check in once.
     */
    function checkIn() external {
        require(isCheckInOpen, "Check-in is not currently open.");
        require(attendees[msg.sender] == 0, "You have already checked in.");

        uint256 checkInTime = block.timestamp;
        attendees[msg.sender] = checkInTime;
        attendeeList.push(msg.sender);

        emit CheckedIn(msg.sender, checkInTime);
    }

    /**
     * @dev Allows the owner to open the check-in period.
     */
    function openCheckIn() external onlyOwner {
        require(!isCheckInOpen, "Check-in is already open.");
        isCheckInOpen = true;
        emit CheckInOpened();
    }

    /**
     * @dev Allows the owner to close the check-in period.
     */
    function closeCheckIn() external onlyOwner {
        require(isCheckInOpen, "Check-in is already closed.");
        isCheckInOpen = false;
        emit CheckInClosed();
    }

    /**
     * @dev Verifies if a specific address has checked in.
     * @param _attendee The address to check.
     * @return True if the address has checked in, false otherwise.
     */
    function hasCheckedIn(address _attendee) external view returns (bool) {
        return attendees[_attendee] > 0;
    }

    /**
     * @dev Returns the timestamp of when a specific attendee checked in.
     * @param _attendee The address of the attendee.
     * @return The check-in timestamp, or 0 if they haven't checked in.
     */
    function getCheckInTime(address _attendee) external view returns (uint256) {
        return attendees[_attendee];
    }

    /**
     * @dev Returns the total number of attendees who have checked in.
     * @return The count of attendees.
     */
    function getAttendeeCount() external view returns (uint256) {
        return attendeeList.length;
    }

    /**
     * @dev Returns the list of all attendees.
     * @return An array of attendee addresses.
     */
    function getAllAttendees() external view returns (address[] memory) {
        return attendeeList;
    }
}
