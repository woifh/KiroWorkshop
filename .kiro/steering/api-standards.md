---
inclusion: fileMatch
fileMatchPattern: '(main|api|routes|endpoints|controllers)\.py'
---

# API Standards and Conventions

This steering file defines REST API standards and conventions for the Events API project. It will automatically load when working on API-related Python files (main.py, api.py, routes.py, endpoints.py, controllers.py) to provide consistent guidance.

## HTTP Methods

Use HTTP methods according to their semantic meaning:

- **GET**: Retrieve resources (read-only, idempotent, cacheable)
- **POST**: Create new resources (non-idempotent)
- **PUT**: Update entire resources (idempotent)
- **PATCH**: Partial update of resources (idempotent)
- **DELETE**: Remove resources (idempotent)

## HTTP Status Codes

### Success Codes (2xx)

- **200 OK**: Successful GET, PUT, PATCH, or DELETE
- **201 Created**: Successful POST that creates a resource
- **204 No Content**: Successful DELETE with no response body

### Client Error Codes (4xx)

- **400 Bad Request**: Invalid request syntax or validation error
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Authenticated but not authorized
- **404 Not Found**: Resource does not exist
- **409 Conflict**: Request conflicts with current state
- **422 Unprocessable Entity**: Validation error with detailed feedback

### Server Error Codes (5xx)

- **500 Internal Server Error**: Unexpected server error
- **503 Service Unavailable**: Temporary unavailability

## REST API Conventions

### Resource Naming

- Use plural nouns for collections: `/events`, `/users`
- Use singular identifiers: `/events/{id}`
- Use kebab-case for multi-word resources: `/event-categories`
- Avoid verbs in URLs (use HTTP methods instead)

### URL Structure

```
GET    /events           # List all events
POST   /events           # Create new event
GET    /events/{id}      # Get specific event
PUT    /events/{id}      # Update entire event
PATCH  /events/{id}      # Partial update event
DELETE /events/{id}      # Delete event
```

### Query Parameters

- Use for filtering: `?status=active`
- Use for pagination: `?page=1&limit=20`
- Use for sorting: `?sort=date&order=desc`
- Use for field selection: `?fields=title,date`

## JSON Response Format Standards

### Success Response Format

**For single resources** (GET /events/{id}, POST /events, PUT /events/{id}):

Return the resource directly without a wrapper:

```json
{
  "eventId": "abc-123",
  "title": "Event Title",
  "description": "Event description",
  "date": "2025-12-15",
  "location": "Seattle, WA",
  "capacity": 50,
  "organizer": "Team Name",
  "status": "active"
}
```

**For collections without pagination** (GET /events with small datasets):

Return an array directly:

```json
[
  {
    "eventId": "abc-123",
    "title": "Event 1",
    "description": "Description 1",
    "date": "2025-12-15",
    "location": "Seattle, WA",
    "capacity": 50,
    "organizer": "Team Name",
    "status": "active"
  },
  {
    "eventId": "def-456",
    "title": "Event 2",
    "description": "Description 2",
    "date": "2025-12-20",
    "location": "Portland, OR",
    "capacity": 100,
    "organizer": "Another Team",
    "status": "active"
  }
]
```

**For paginated collections** (GET /events?page=1&limit=20):

Use a wrapper with pagination metadata:

```json
{
  "data": [
    {
      "eventId": "abc-123",
      "title": "Event 1",
      ...
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### Error Response Format

All error responses must follow this structure:

```json
{
  "detail": "Error message",
  "message": "Human-readable error description",
  "errors": [                    // Optional: for validation errors
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

Examples:

**400 Bad Request:**
```json
{
  "detail": "Invalid input data",
  "message": "The request contains invalid or missing fields"
}
```

**404 Not Found:**
```json
{
  "detail": "Event not found",
  "message": "No event exists with the provided ID"
}
```

**422 Validation Error:**
```json
{
  "detail": [
    {
      "loc": ["body", "capacity"],
      "msg": "ensure this value is greater than 0",
      "type": "value_error.number.not_gt"
    }
  ],
  "message": "Invalid input data"
}
```

**500 Internal Server Error:**
```json
{
  "detail": "Internal server error",
  "message": "An unexpected error occurred. Please try again later."
}
```

## Field Naming Conventions

- Use camelCase for JSON field names: `eventId`, `firstName`
- Use consistent naming across all endpoints
- Use ISO 8601 format for dates: `2025-12-15T10:30:00Z`
- Use ISO 4217 for currency codes: `USD`, `EUR`

## Validation Standards

### Request Validation

- Validate all input data before processing
- Return 422 status code for validation errors
- Include field-specific error messages
- Validate data types, formats, and constraints

### Field Constraints

- String fields: Define min/max length
- Numeric fields: Define min/max values
- Date fields: Validate format and logical constraints
- Enum fields: Validate against allowed values

Example validation in Pydantic:
```python
class EventCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    capacity: int = Field(..., gt=0, le=100000)
    status: Literal["active", "cancelled", "completed"]
```

## CORS Configuration

- Enable CORS for web client access
- Configure allowed origins appropriately
- Allow standard HTTP methods
- Allow necessary headers

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Error Handling Best Practices

1. **Catch Specific Exceptions**: Handle specific error types appropriately
2. **Log Errors**: Log all errors with context for debugging
3. **Hide Internal Details**: Don't expose stack traces or internal paths
4. **Provide Actionable Messages**: Tell users what went wrong and how to fix it
5. **Use Consistent Format**: All errors follow the same JSON structure

Example error handler:
```python
@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unexpected error: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "message": str(exc)
        }
    )
```

## API Documentation

- Document all endpoints with clear descriptions
- Include request/response examples
- Document all possible status codes
- Keep documentation up-to-date with code changes
- Use tools like pdoc, Swagger/OpenAPI for auto-generation

## API Versioning

Use URL path versioning for major API changes:

```
/v1/events
/v2/events
```

- Version in the URL path (not headers or query params)
- Only increment for breaking changes
- Maintain backward compatibility within a version
- Document deprecation timeline for old versions

Example:
```python
app = FastAPI(title="Events API", version="1.0.0")

# Version 1 routes
@app.get("/v1/events")
async def list_events_v1():
    ...

# Version 2 routes (with breaking changes)
@app.get("/v2/events")
async def list_events_v2():
    ...
```

## Authentication and Authorization

### JWT Token-Based Authentication

Use JWT (JSON Web Tokens) for stateless authentication:

**Token Format:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**JWT Payload Structure:**
```json
{
  "sub": "user-id-123",
  "email": "user@example.com",
  "role": "admin",
  "exp": 1735689600,
  "iat": 1735603200
}
```

**Implementation Example:**

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from datetime import datetime, timedelta

security = HTTPBearer()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = "HS256"

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=24))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

# Protected endpoint example
@app.get("/events/private")
async def get_private_events(token_data: dict = Depends(verify_token)):
    user_id = token_data.get("sub")
    # Use user_id to fetch user-specific data
    return {"message": f"Private events for user {user_id}"}
```

### Role-Based Access Control (RBAC)

Implement role-based permissions:

```python
from enum import Enum
from typing import List

class Role(str, Enum):
    ADMIN = "admin"
    ORGANIZER = "organizer"
    USER = "user"

def require_roles(allowed_roles: List[Role]):
    def role_checker(token_data: dict = Depends(verify_token)):
        user_role = token_data.get("role")
        if user_role not in [role.value for role in allowed_roles]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        return token_data
    return role_checker

# Admin-only endpoint
@app.delete("/events/{event_id}")
async def delete_event(
    event_id: str,
    token_data: dict = Depends(require_roles([Role.ADMIN, Role.ORGANIZER]))
):
    # Only admins and organizers can delete events
    return {"message": "Event deleted"}

# Public endpoint (no auth required)
@app.get("/events")
async def list_events():
    return []
```

### Authentication Headers

**Request Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Response Headers for Auth Errors:**
```
WWW-Authenticate: Bearer realm="Events API"
```

## Rate Limiting

Implement rate limiting to prevent abuse:

**Response Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1735689600
```

**Implementation Example:**

```python
from fastapi import Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/events")
@limiter.limit("100/hour")
async def list_events(request: Request):
    return []
```

**Rate Limit Exceeded Response (429):**
```json
{
  "detail": "Rate limit exceeded",
  "message": "Too many requests. Please try again in 3600 seconds."
}
```

## Security Best Practices

- **Input Validation**: Validate and sanitize all inputs using Pydantic
- **HTTPS Only**: Use HTTPS in production, redirect HTTP to HTTPS
- **Rate Limiting**: Implement per-user and per-IP rate limits
- **Authentication**: Use JWT tokens with short expiration times
- **Authorization**: Implement RBAC for fine-grained access control
- **Secrets Management**: Use environment variables, never hardcode secrets
- **CORS**: Configure allowed origins appropriately (not `*` in production)
- **SQL Injection**: Use parameterized queries (ORM handles this)
- **XSS Prevention**: Sanitize user input, escape output
- **Sensitive Data**: Never log or expose passwords, tokens, or PII
- **Error Messages**: Don't expose internal details in production errors

## Complete Endpoint Implementation Example

Here's a complete example showing POST endpoint with validation, error handling, and proper status codes:

```python
from fastapi import FastAPI, HTTPException, status, Depends
from pydantic import BaseModel, Field, field_validator
from typing import Optional
import logging

logger = logging.getLogger(__name__)
app = FastAPI()

# Model with validation
class EventCreate(BaseModel):
    eventId: Optional[str] = Field(None, description="Optional custom event ID")
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1, max_length=2000)
    date: str = Field(..., description="ISO format: YYYY-MM-DD")
    location: str = Field(..., min_length=1, max_length=200)
    capacity: int = Field(..., gt=0, le=100000)
    organizer: str = Field(..., min_length=1, max_length=200)
    status: Literal["active", "cancelled", "completed"] = Field(default="active")

    @field_validator('date')
    @classmethod
    def validate_date(cls, v: str) -> str:
        try:
            datetime.fromisoformat(v)
            return v
        except ValueError:
            raise ValueError('Date must be in ISO format (YYYY-MM-DD)')

# POST endpoint with full error handling
@app.post("/events", response_model=Event, status_code=status.HTTP_201_CREATED)
async def create_event(
    event: EventCreate,
    token_data: dict = Depends(verify_token)  # Optional: add auth
):
    """
    Create a new event.
    
    - **eventId**: Optional custom ID (auto-generated if not provided)
    - **title**: Event title (1-200 characters)
    - **description**: Event description (1-2000 characters)
    - **date**: Event date in ISO format (YYYY-MM-DD)
    - **location**: Event location (1-200 characters)
    - **capacity**: Event capacity (1-100,000)
    - **organizer**: Event organizer (1-200 characters)
    - **status**: Event status (active, cancelled, completed)
    
    Returns the created event with generated ID.
    """
    try:
        logger.info(f"Creating event: {event.title}")
        
        # Business logic validation
        if event.capacity < 10:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Capacity must be at least 10 for public events"
            )
        
        # Check for duplicate
        existing = db.get_event_by_title(event.title)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Event with this title already exists"
            )
        
        # Create event
        created_event = db.create_event(event)
        logger.info(f"Event created successfully: {created_event.eventId}")
        
        return created_event
        
    except HTTPException:
        raise  # Re-raise HTTP exceptions
    except Exception as e:
        logger.error(f"Error creating event: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create event"
        )

# GET endpoint with optional auth
@app.get("/events/{event_id}", response_model=Event)
async def get_event(event_id: str):
    """Get a specific event by ID."""
    try:
        logger.info(f"Fetching event: {event_id}")
        event = db.get_event(event_id)
        
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Event not found"
            )
        
        return event
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching event: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve event"
        )

# PUT endpoint with auth
@app.put("/events/{event_id}", response_model=Event)
async def update_event(
    event_id: str,
    event_update: EventUpdate,
    token_data: dict = Depends(require_roles([Role.ADMIN, Role.ORGANIZER]))
):
    """Update an event (requires admin or organizer role)."""
    try:
        logger.info(f"Updating event: {event_id}")
        
        # Check if event exists
        existing = db.get_event(event_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Event not found"
            )
        
        # Update event
        updated_event = db.update_event(event_id, event_update)
        logger.info(f"Event updated successfully: {event_id}")
        
        return updated_event
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating event: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update event"
        )

# DELETE endpoint with auth
@app.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_event(
    event_id: str,
    token_data: dict = Depends(require_roles([Role.ADMIN]))
):
    """Delete an event (admin only)."""
    try:
        logger.info(f"Deleting event: {event_id}")
        
        success = db.delete_event(event_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Event not found"
            )
        
        logger.info(f"Event deleted successfully: {event_id}")
        return None  # 204 No Content
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting event: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete event"
        )
```

## Testing Standards

### Test Structure

Use pytest with FastAPI's TestClient:

```python
from fastapi.testclient import TestClient
from main import app
import pytest

client = TestClient(app)

# Test data fixtures
@pytest.fixture
def sample_event():
    return {
        "title": "Test Event",
        "description": "Test description",
        "date": "2025-12-15",
        "location": "Test Location",
        "capacity": 50,
        "organizer": "Test Organizer",
        "status": "active"
    }

@pytest.fixture
def auth_headers():
    token = create_access_token({"sub": "test-user", "role": "admin"})
    return {"Authorization": f"Bearer {token}"}
```

### Test Examples

**Test successful creation:**
```python
def test_create_event_success(sample_event):
    response = client.post("/events", json=sample_event)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == sample_event["title"]
    assert "eventId" in data
```

**Test validation error:**
```python
def test_create_event_invalid_capacity(sample_event):
    sample_event["capacity"] = -10
    response = client.post("/events", json=sample_event)
    assert response.status_code == 422
    assert "detail" in response.json()
```

**Test not found:**
```python
def test_get_event_not_found():
    response = client.get("/events/nonexistent-id")
    assert response.status_code == 404
    assert response.json()["detail"] == "Event not found"
```

**Test authentication:**
```python
def test_delete_event_unauthorized():
    response = client.delete("/events/test-id")
    assert response.status_code == 401

def test_delete_event_forbidden(auth_headers):
    # User without admin role
    user_token = create_access_token({"sub": "user", "role": "user"})
    headers = {"Authorization": f"Bearer {user_token}"}
    response = client.delete("/events/test-id", headers=headers)
    assert response.status_code == 403

def test_delete_event_success(auth_headers):
    # Create event first
    event = client.post("/events", json=sample_event).json()
    event_id = event["eventId"]
    
    # Delete with admin token
    response = client.delete(f"/events/{event_id}", headers=auth_headers)
    assert response.status_code == 204
```

**Test pagination:**
```python
def test_list_events_pagination():
    response = client.get("/events?page=1&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert "pagination" in data
    assert data["pagination"]["page"] == 1
    assert data["pagination"]["limit"] == 10
```

**Test rate limiting:**
```python
def test_rate_limit():
    # Make requests until rate limit is hit
    for i in range(101):
        response = client.get("/events")
        if i < 100:
            assert response.status_code == 200
        else:
            assert response.status_code == 429
            assert "X-RateLimit-Limit" in response.headers
```

### Testing Best Practices

- **Test Coverage**: Aim for >80% code coverage
- **Test Isolation**: Each test should be independent
- **Use Fixtures**: Share common test data with pytest fixtures
- **Mock External Services**: Mock database, external APIs, etc.
- **Test Edge Cases**: Empty strings, null values, boundary conditions
- **Test Error Paths**: Ensure errors are handled gracefully
- **Integration Tests**: Test full request/response cycle
- **Performance Tests**: Test response times for critical endpoints
