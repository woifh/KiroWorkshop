# Requirements Document

## Introduction

The user registration feature enables users to register for events with capacity management and waitlist functionality. Users can create basic profiles, register for events, and manage their event registrations. The system enforces event capacity constraints and automatically manages waitlists when events reach full capacity.

## Glossary

- **User**: An individual with a unique identifier and name who can register for events
- **Event Registration**: The process of a user signing up to attend an event
- **Event Capacity**: The maximum number of users that can register for an event
- **Waitlist**: A queue of users waiting for spots to become available in a full event
- **Registration System**: The component responsible for managing user registrations to events
- **User System**: The component responsible for creating and managing user profiles
- **Event System**: The existing component that manages event information and capacity

## Requirements

### Requirement 1: User Creation

**User Story:** As a new user, I want to create a user profile with my basic information, so that I can register for events.

#### Acceptance Criteria

1. WHEN a user submits a name, THE User System SHALL create a new user with a unique user ID
2. WHEN a user attempts to create a profile without a name, THE User System SHALL reject the request and return a validation error
3. THE User System SHALL generate a unique user ID using UUID format
4. THE User System SHALL store the user's name with a maximum length of 200 characters
5. WHEN a user is created, THE User System SHALL return the complete user object including the generated user ID

### Requirement 2: Event Capacity Configuration

**User Story:** As an event organizer, I want to configure event capacity with an optional waitlist, so that I can manage event attendance effectively.

#### Acceptance Criteria

1. WHEN an event is created with a capacity value, THE Event System SHALL enforce that capacity as the maximum number of registrations
2. WHEN an event is created with a waitlist flag set to true, THE Event System SHALL enable waitlist functionality for that event
3. THE Event System SHALL allow capacity values between 1 and 100000
4. WHEN an event has no waitlist configured and reaches capacity, THE Event System SHALL reject new registration attempts
5. THE Event System SHALL store the current registration count and waitlist count for each event

### Requirement 3: Event Registration

**User Story:** As a user, I want to register for an event, so that I can attend and participate.

#### Acceptance Criteria

1. WHEN a user registers for an event with available capacity, THE Registration System SHALL add the user to the event's registered users list
2. WHEN a user attempts to register for an event they are already registered for, THE Registration System SHALL reject the request and return a conflict error
3. WHEN a user registers for an event, THE Registration System SHALL increment the event's registration count
4. WHEN a user successfully registers, THE Registration System SHALL return a confirmation with registration details
5. THE Registration System SHALL validate that both the user ID and event ID exist before processing registration

### Requirement 4: Full Event Handling

**User Story:** As a user, I want to be notified when an event is full, so that I know I cannot register.

#### Acceptance Criteria

1. WHEN a user attempts to register for an event at full capacity without a waitlist, THE Registration System SHALL deny the registration and return a capacity error
2. WHEN an event reaches full capacity, THE Registration System SHALL mark the event status as full
3. THE Registration System SHALL calculate available capacity by subtracting registered users from total capacity
4. WHEN checking capacity, THE Registration System SHALL include only confirmed registrations in the count
5. THE Registration System SHALL return the current capacity status in error messages

### Requirement 5: Waitlist Management

**User Story:** As a user, I want to join a waitlist when an event is full, so that I can attend if a spot becomes available.

#### Acceptance Criteria

1. WHEN a user attempts to register for a full event with waitlist enabled, THE Registration System SHALL add the user to the waitlist
2. WHEN a user is added to the waitlist, THE Registration System SHALL assign a position number based on join order
3. THE Registration System SHALL prevent users from being on both the registered list and waitlist simultaneously
4. WHEN a user on the waitlist attempts to register again, THE Registration System SHALL reject the request and return their current waitlist position
5. THE Registration System SHALL store the timestamp when each user joins the waitlist

### Requirement 6: Event Unregistration

**User Story:** As a registered user, I want to unregister from an event, so that I can free up my spot if I cannot attend.

#### Acceptance Criteria

1. WHEN a registered user unregisters from an event, THE Registration System SHALL remove the user from the registered users list
2. WHEN a user unregisters, THE Registration System SHALL decrement the event's registration count
3. WHEN a user unregisters from a full event with a waitlist, THE Registration System SHALL automatically register the first user from the waitlist
4. WHEN a waitlisted user is promoted to registered, THE Registration System SHALL remove them from the waitlist
5. WHEN a user attempts to unregister from an event they are not registered for, THE Registration System SHALL return a not found error

### Requirement 7: User Event Listing

**User Story:** As a user, I want to view all events I am registered for, so that I can track my upcoming events.

#### Acceptance Criteria

1. WHEN a user requests their registered events, THE Registration System SHALL return a list of all events the user is registered for
2. THE Registration System SHALL include event details such as title, date, location, and capacity in the response
3. THE Registration System SHALL indicate whether the user is registered or on the waitlist for each event
4. WHEN a user has no registrations, THE Registration System SHALL return an empty list
5. THE Registration System SHALL order events by date with the nearest events first
6. THE Registration System SHALL include waitlist position when the user is on a waitlist
7. THE Registration System SHALL validate that user IDs are valid UUID format before querying
8. THE Registration System SHALL maintain three distinct states for each user-event pair: not registered, registered, or waitlisted
