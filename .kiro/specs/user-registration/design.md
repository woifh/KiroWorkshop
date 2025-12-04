# Design Document

## Overview

The user registration feature extends the existing Events API to support user profiles and event registration management. The system will implement a registration service that manages user-event relationships, enforces capacity constraints, and handles waitlist functionality. The design follows RESTful principles and integrates seamlessly with the existing DynamoDB-based architecture.

## Architecture

### High-Level Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│      API Gateway (Existing)         │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│   Lambda Function (FastAPI)         │
│  ┌──────────────────────────────┐   │
│  │  User Endpoints              │   │
│  │  Registration Endpoints      │   │
│  │  Event Endpoints (Existing)  │   │
│  └──────────────────────────────┘   │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│         DynamoDB                    │
│  ┌────────────┐  ┌──────────────┐  │
│  │   Users    │  │ Registrations│  │
│  │   Table    │  │    Table     │  │
│  └────────────┘  └──────────────┘  │
│  ┌────────────┐                    │
│  │   Events   │                    │
│  │   Table    │                    │
│  │ (Existing) │                    │
│  └────────────┘                    │
└─────────────────────────────────────┘
```

### Component Interaction Flow

**User Registration Flow:**
1. Client sends POST request to `/users`
2. API validates input (name required, 1-200 chars)
3. Generate UUID for userId
4. Store user in DynamoDB Users table
5. Return user object with userId

**Event Registration Flow:**
1. Client sends POST request to `/events/{eventId}/register`
2. Validate user exists and event exists
3. Check current registration count vs capacity
4. If capacity available: add to registrations, increment count
5. If full and waitlist enabled: add to waitlist with position
6. If full and no waitlist: return 409 Conflict error
7. Return registration confirmation

**Unregistration with Waitlist Promotion:**
1. Client sends DELETE request to `/events/{eventId}/register/{userId}`
2. Remove user from registrations
3. Decrement registration count
4. If waitlist exists and not empty:
   - Get first user from waitlist (FIFO)
   - Move to registrations
   - Remove from waitlist
   - Update positions for remaining waitlist users
5. Return success response

## Components and Interfaces

### User Service

**Responsibilities:**
- Create and manage user profiles
- Validate user data
- Query user information

**Endpoints:**
- `POST /users` - Create new user
- `GET /users/{userId}` - Get user by ID
- `GET /users` - List all users (optional, for admin)

### Registration Service

**Responsibilities:**
- Manage event registrations
- Enforce capacity constraints
- Handle waitlist operations
- Track registration states

**Endpoints:**
- `POST /events/{eventId}/register` - Register user for event
- `DELETE /events/{eventId}/register/{userId}` - Unregister user
- `GET /users/{userId}/registrations` - List user's registrations
- `GET /events/{eventId}/registrations` - List event registrations (optional)

### Event Service (Enhanced)

**Responsibilities:**
- Existing event CRUD operations
- Add capacity and waitlist configuration
- Track registration counts

**Modified Fields:**
- Add `capacity` field (integer, 1-100000)
- Add `hasWaitlist` field (boolean, default false)
- Add `registeredCount` field (integer, default 0)
- Add `waitlistCount` field (integer, default 0)

## Data Models

### User Model

```python
class User(BaseModel):
    userId: str = Field(..., description="Unique user identifier (UUID)")
    name: str = Field(..., min_length=1, max_length=200, description="User's name")
    createdAt: str = Field(..., description="ISO 8601 timestamp")
    
class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200, description="User's name")
```

**DynamoDB Schema (Users Table):**
- Partition Key: `userId` (String)
- Attributes:
  - `name` (String)
  - `createdAt` (String, ISO 8601)

### Registration Model

```python
class Registration(BaseModel):
    registrationId: str = Field(..., description="Unique registration ID (UUID)")
    userId: str = Field(..., description="User ID")
    eventId: str = Field(..., description="Event ID")
    status: Literal["registered", "waitlisted"] = Field(..., description="Registration status")
    registeredAt: str = Field(..., description="ISO 8601 timestamp")
    waitlistPosition: Optional[int] = Field(None, description="Position in waitlist if applicable")

class RegistrationCreate(BaseModel):
    userId: str = Field(..., description="User ID (UUID format)")
    
class RegistrationResponse(BaseModel):
    registrationId: str
    userId: str
    eventId: str
    status: Literal["registered", "waitlisted"]
    registeredAt: str
    waitlistPosition: Optional[int] = None
    message: str
```

**DynamoDB Schema (Registrations Table):**
- Partition Key: `registrationId` (String, UUID)
- Global Secondary Index 1: `userId-eventId-index`
  - Partition Key: `userId`
  - Sort Key: `eventId`
- Global Secondary Index 2: `eventId-status-index`
  - Partition Key: `eventId`
  - Sort Key: `status`
- Attributes:
  - `userId` (String)
  - `eventId` (String)
  - `status` (String: "registered" | "waitlisted")
  - `registeredAt` (String, ISO 8601)
  - `waitlistPosition` (Number, optional)

### Enhanced Event Model

```python
class Event(BaseModel):
    eventId: str
    title: str
    description: str
    date: str
    location: str
    capacity: int = Field(..., gt=0, le=100000, description="Maximum attendees")
    hasWaitlist: bool = Field(default=False, description="Enable waitlist when full")
    registeredCount: int = Field(default=0, description="Current registration count")
    waitlistCount: int = Field(default=0, description="Current waitlist count")
    organizer: str
    status: Literal["active", "cancelled", "completed"]

class EventCreate(BaseModel):
    # ... existing fields ...
    capacity: int = Field(..., gt=0, le=100000)
    hasWaitlist: bool = Field(default=False)
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: User Creation Generates Unique IDs

*For any* user creation request with a valid name, the system should generate a unique UUID that does not conflict with existing user IDs.

**Validates: Requirements 1.1, 1.3**

### Property 2: Registration Respects Capacity Limits

*For any* event with defined capacity, the number of registered users should never exceed the capacity value.

**Validates: Requirements 2.1, 3.1, 4.1**

### Property 3: Waitlist Activation on Full Capacity

*For any* event that is full and has waitlist enabled, registration attempts should result in waitlist addition rather than rejection.

**Validates: Requirements 4.1, 5.1**

### Property 4: No Duplicate Registrations

*For any* user-event pair, there should exist at most one registration record with status "registered" or "waitlisted".

**Validates: Requirements 3.2, 5.4**

### Property 5: Waitlist FIFO Ordering

*For any* event waitlist, when a spot becomes available, the user with the earliest `registeredAt` timestamp and status "waitlisted" should be promoted first.

**Validates: Requirements 5.2, 6.3**

### Property 6: Unregistration Decrements Count

*For any* successful unregistration, the event's `registeredCount` should decrease by exactly 1.

**Validates: Requirements 6.2**

### Property 7: Automatic Waitlist Promotion

*For any* unregistration from a full event with a non-empty waitlist, exactly one user should be automatically promoted from waitlist to registered status.

**Validates: Requirements 6.3, 6.4**

### Property 8: Registration State Consistency

*For any* user-event pair, the registration status in the Registrations table should match the counts in the Events table (registeredCount and waitlistCount).

**Validates: Requirements 7.8**

### Property 9: User Event List Completeness

*For any* user, querying their registrations should return all events where a registration record exists for that userId.

**Validates: Requirements 7.1**

### Property 10: Waitlist Position Accuracy

*For any* waitlisted user, their position should equal the count of waitlisted users for that event with earlier `registeredAt` timestamps plus 1.

**Validates: Requirements 5.2, 7.6**

## Error Handling

### Error Scenarios and Responses

**User Creation Errors:**
- 400 Bad Request: Invalid name (empty or > 200 chars)
- 422 Unprocessable Entity: Validation errors
- 500 Internal Server Error: Database errors

**Registration Errors:**
- 404 Not Found: User or event doesn't exist
- 409 Conflict: User already registered or on waitlist
- 409 Conflict: Event full (no waitlist)
- 422 Unprocessable Entity: Invalid UUID format
- 500 Internal Server Error: Database errors

**Unregistration Errors:**
- 404 Not Found: Registration doesn't exist
- 404 Not Found: User or event doesn't exist
- 500 Internal Server Error: Database errors

### Error Response Format

All errors follow the API standards:

```json
{
  "detail": "Error message",
  "message": "Human-readable description"
}
```

### Logging Strategy

- Log all user creation with userId and timestamp
- Log all registration attempts (success and failure)
- Log waitlist promotions with user IDs
- Log capacity violations
- Never log sensitive user data
- Include request IDs for tracing

## Testing Strategy

### Unit Tests

**User Service Tests:**
- Test user creation with valid name
- Test user creation with invalid name (empty, too long)
- Test user retrieval by ID
- Test user not found scenario

**Registration Service Tests:**
- Test registration with available capacity
- Test registration when event is full (no waitlist)
- Test waitlist addition when event is full (with waitlist)
- Test duplicate registration prevention
- Test unregistration
- Test waitlist promotion on unregistration
- Test user registration listing

### Property-Based Tests

Property-based tests will use a Python PBT library (Hypothesis) to verify correctness properties across many randomly generated inputs.

**Configuration:**
- Minimum 100 iterations per property test
- Generate random users, events, and registration sequences
- Test edge cases: capacity=1, capacity=100000, empty waitlists

**Property Test Examples:**

```python
# Property 1: Unique User IDs
@given(st.lists(st.text(min_size=1, max_size=200), min_size=2, max_size=100))
def test_user_creation_unique_ids(names):
    """For any list of names, created users should have unique IDs"""
    user_ids = [create_user(name).userId for name in names]
    assert len(user_ids) == len(set(user_ids))

# Property 2: Capacity Enforcement
@given(st.integers(min_value=1, max_value=100), st.integers(min_value=1, max_value=200))
def test_registration_respects_capacity(capacity, num_users):
    """For any event capacity, registrations should not exceed it"""
    event = create_event(capacity=capacity, hasWaitlist=False)
    users = [create_user(f"User{i}") for i in range(num_users)]
    
    registered = 0
    for user in users:
        try:
            register_user(user.userId, event.eventId)
            registered += 1
        except ConflictError:
            pass
    
    assert registered <= capacity

# Property 3: Waitlist FIFO
@given(st.integers(min_value=1, max_value=10))
def test_waitlist_fifo_order(num_waitlisted):
    """For any waitlist, promotion should follow FIFO order"""
    event = create_event(capacity=1, hasWaitlist=True)
    first_user = create_user("First")
    register_user(first_user.userId, event.eventId)
    
    waitlist_users = [create_user(f"Wait{i}") for i in range(num_waitlisted)]
    for user in waitlist_users:
        register_user(user.userId, event.eventId)
    
    unregister_user(first_user.userId, event.eventId)
    
    registrations = get_event_registrations(event.eventId)
    promoted = [r for r in registrations if r.status == "registered"][0]
    assert promoted.userId == waitlist_users[0].userId
```

### Integration Tests

- Test complete registration flow end-to-end
- Test waitlist promotion flow
- Test concurrent registrations (race conditions)
- Test database consistency after operations
- Test API responses match expected formats

### Edge Cases to Test

- Event with capacity=1
- Event with capacity=100000
- Simultaneous registrations at capacity limit
- Unregistration when waitlist is empty
- Unregistration when waitlist has 1 user
- User with 0 registrations
- User with many registrations
- Invalid UUID formats
- Non-existent user/event IDs

## Performance Considerations

### Database Optimization

- Use GSI for efficient user registration queries
- Use GSI for efficient event registration queries
- Batch operations where possible
- Implement pagination for large result sets

### Caching Strategy

- Cache event capacity and counts (with TTL)
- Invalidate cache on registration/unregistration
- Consider DynamoDB DAX for read-heavy workloads

### Scalability

- DynamoDB auto-scaling for variable load
- Lambda concurrency limits to prevent overload
- API Gateway throttling for rate limiting
- Consider SQS for waitlist promotion notifications

## Security Considerations

- Validate all UUIDs to prevent injection
- Sanitize user names to prevent XSS
- Implement rate limiting per user/IP
- Log all operations for audit trail
- Use IAM roles for DynamoDB access
- Encrypt data at rest (DynamoDB encryption)
- Use HTTPS for all API calls

## Deployment Strategy

### Database Migration

1. Create Users table with GSI
2. Create Registrations table with GSIs
3. Add new fields to Events table (capacity, hasWaitlist, counts)
4. Update existing events with default values

### Code Deployment

1. Deploy new models (User, Registration)
2. Deploy database clients
3. Deploy API endpoints
4. Update CDK stack with new tables
5. Run integration tests
6. Deploy to production

### Rollback Plan

- Keep old Events table structure compatible
- Feature flag for new registration endpoints
- Ability to disable waitlist functionality
- Database backup before migration

## Future Enhancements

- Email notifications for waitlist promotions
- Event reminder notifications
- User preferences and settings
- Event categories and tags
- Advanced search and filtering
- Analytics dashboard for organizers
- Bulk registration operations
- Registration deadlines
- Payment integration for paid events
