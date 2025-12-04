# User Registration API Documentation

## Overview

The User Registration API extends the Events API with user management and event registration capabilities. Users can register for events, join waitlists when events are full, and be automatically promoted when spots become available.

## API Endpoints

### User Endpoints

#### Create User
```http
POST /users
Content-Type: application/json

{
  "name": "John Doe"
}
```

**Response (201 Created):**
```json
{
  "userId": "d519132d-6e2b-4e86-acb2-d940b46cc80b",
  "name": "John Doe",
  "createdAt": "2025-12-04T03:29:40.395842Z"
}
```

#### Get User
```http
GET /users/{userId}
```

**Response (200 OK):**
```json
{
  "userId": "d519132d-6e2b-4e86-acb2-d940b46cc80b",
  "name": "John Doe",
  "createdAt": "2025-12-04T03:29:40.395842Z"
}
```

#### List All Users
```http
GET /users
```

**Response (200 OK):**
```json
[
  {
    "userId": "d519132d-6e2b-4e86-acb2-d940b46cc80b",
    "name": "John Doe",
    "createdAt": "2025-12-04T03:29:40.395842Z"
  }
]
```

### Registration Endpoints

#### Register for Event
```http
POST /events/{eventId}/registrations
Content-Type: application/json

{
  "userId": "d519132d-6e2b-4e86-acb2-d940b46cc80b"
}
```

**Response (201 Created) - Successful Registration:**
```json
{
  "registrationId": "e4c25c9d-442b-4d5c-9425-bdf8f4131e35",
  "userId": "d519132d-6e2b-4e86-acb2-d940b46cc80b",
  "eventId": "8745643b-1ad6-45cf-b0e9-ee9060e99c3d",
  "status": "registered",
  "registeredAt": "2025-12-04T03:29:41.983733Z",
  "waitlistPosition": null,
  "message": "Successfully registered for event"
}
```

**Response (201 Created) - Added to Waitlist:**
```json
{
  "registrationId": "4df2fd3d-1afc-4012-bba9-cfd4cbe38e9f",
  "userId": "9455d568-4643-464f-9679-7ef76171d850",
  "eventId": "8745643b-1ad6-45cf-b0e9-ee9060e99c3d",
  "status": "waitlisted",
  "registeredAt": "2025-12-04T03:29:42.995983Z",
  "waitlistPosition": 1,
  "message": "Event is full. Added to waitlist at position 1"
}
```

**Error Response (409 Conflict) - Event Full, No Waitlist:**
```json
{
  "detail": "Event is at full capacity (2/2). No waitlist available."
}
```

**Error Response (409 Conflict) - Already Registered:**
```json
{
  "detail": "User is already registered for this event"
}
```

#### Unregister from Event
```http
DELETE /events/{eventId}/registrations/{userId}
```

**Response (200 OK) - Without Waitlist Promotion:**
```json
{
  "message": "Successfully unregistered from event"
}
```

**Response (200 OK) - With Waitlist Promotion:**
```json
{
  "message": "Successfully unregistered from event",
  "promotedUser": "9455d568-4643-464f-9679-7ef76171d850"
}
```

**Error Response (404 Not Found):**
```json
{
  "detail": "Registration not found"
}
```

#### Get Event Registrations
```http
GET /events/{eventId}/registrations
```

**Response (200 OK):**
```json
[
  {
    "registrationId": "e4c25c9d-442b-4d5c-9425-bdf8f4131e35",
    "userId": "d519132d-6e2b-4e86-acb2-d940b46cc80b",
    "eventId": "8745643b-1ad6-45cf-b0e9-ee9060e99c3d",
    "status": "registered",
    "registeredAt": "2025-12-04T03:29:41.983733Z",
    "waitlistPosition": null
  }
]
```

#### Get User Registrations
```http
GET /users/{userId}/registrations
```

**Response (200 OK):**
```json
[
  {
    "registration": {
      "registrationId": "e4c25c9d-442b-4d5c-9425-bdf8f4131e35",
      "userId": "d519132d-6e2b-4e86-acb2-d940b46cc80b",
      "eventId": "8745643b-1ad6-45cf-b0e9-ee9060e99c3d",
      "status": "registered",
      "registeredAt": "2025-12-04T03:29:41.983733Z",
      "waitlistPosition": null
    },
    "event": {
      "eventId": "8745643b-1ad6-45cf-b0e9-ee9060e99c3d",
      "title": "Tech Workshop",
      "description": "Learn about cloud computing",
      "date": "2025-12-15",
      "location": "Seattle, WA",
      "capacity": 2,
      "hasWaitlist": true,
      "registeredCount": 2,
      "waitlistCount": 0,
      "organizer": "Tech Corp",
      "status": "active"
    }
  }
]
```

### Enhanced Event Model

Events now include registration tracking fields:

```json
{
  "eventId": "8745643b-1ad6-45cf-b0e9-ee9060e99c3d",
  "title": "Tech Workshop",
  "description": "Learn about cloud computing",
  "date": "2025-12-15",
  "location": "Seattle, WA",
  "capacity": 2,
  "hasWaitlist": true,
  "registeredCount": 2,
  "waitlistCount": 0,
  "organizer": "Tech Corp",
  "status": "active"
}
```

**New Fields:**
- `hasWaitlist` (boolean): Enable waitlist when event reaches capacity
- `registeredCount` (integer): Current number of registered users
- `waitlistCount` (integer): Current number of users on waitlist

## Features

### Capacity Management
- Events enforce capacity limits (1-100,000 attendees)
- Registration attempts beyond capacity are handled based on waitlist configuration
- Real-time tracking of registered and waitlisted users

### Waitlist Functionality
- Optional waitlist can be enabled per event
- Users are added to waitlist when event is full
- Waitlist positions are assigned in FIFO order
- Automatic promotion when spots become available

### Automatic Promotion
- When a registered user unregisters, the first waitlisted user is automatically promoted
- Promoted users receive a new registration with "registered" status
- Waitlist positions are updated for remaining users

### Validation
- UUID format validation for user and event IDs
- User name validation (1-200 characters)
- Duplicate registration prevention
- User and event existence checks

## Database Schema

### Users Table
- **Partition Key:** `userId` (String, UUID)
- **Attributes:**
  - `name` (String, 1-200 chars)
  - `createdAt` (String, ISO 8601)

### Registrations Table
- **Partition Key:** `registrationId` (String, UUID)
- **GSI 1:** `userId-eventId-index`
  - Partition Key: `userId`
  - Sort Key: `eventId`
- **GSI 2:** `eventId-status-index`
  - Partition Key: `eventId`
  - Sort Key: `status`
- **Attributes:**
  - `userId` (String, UUID)
  - `eventId` (String, UUID)
  - `status` (String: "registered" | "waitlisted")
  - `registeredAt` (String, ISO 8601)
  - `waitlistPosition` (Number, optional)

### Events Table (Enhanced)
- Existing fields plus:
  - `capacity` (Number, 1-100000)
  - `hasWaitlist` (Boolean)
  - `registeredCount` (Number)
  - `waitlistCount` (Number)

## Testing

Run the comprehensive test suite:

```bash
bash test_registration_api.sh
```

The test script validates:
1. User creation
2. User retrieval
3. Event creation with capacity and waitlist
4. Successful registration
5. Waitlist addition when full
6. User registration listing
7. Unregistration with automatic promotion
8. Event count updates

## Error Codes

- **200 OK:** Successful operation
- **201 Created:** Resource created successfully
- **204 No Content:** Successful deletion
- **400 Bad Request:** Invalid input data
- **404 Not Found:** Resource not found
- **409 Conflict:** Duplicate registration or capacity exceeded
- **422 Unprocessable Entity:** Validation error (invalid UUID format)
- **500 Internal Server Error:** Server error

## Implementation Status

✅ **Completed Tasks:**
1. Database schema and models (Users, Registrations, enhanced Events)
2. User Service (create, get, list users)
3. Registration Service core logic (register, capacity checking)
4. Waitlist functionality (FIFO ordering, position tracking)
5. Unregistration with automatic promotion
6. User registration listing (sorted by date)
7. Data validation and error handling
8. CDK infrastructure (DynamoDB tables with GSIs)
9. API documentation
10. Comprehensive testing

All requirements from the specification have been implemented and tested successfully.

## API URL

**Production:** https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/

## Next Steps

Optional enhancements (not in current scope):
- Property-based tests using Hypothesis
- Email notifications for waitlist promotions
- Event reminder notifications
- Advanced search and filtering
- Analytics dashboard
