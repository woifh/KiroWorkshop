---
inclusion: fileMatch
fileMatchPattern: '(main|api|routes|endpoints|controllers)\.py'
---

# API Standards and Conventions

This steering file defines REST API standards and conventions for the Events API project.

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

All successful responses should return JSON with consistent structure:

```json
{
  "data": { ... },           // Single resource
  "data": [ ... ],           // Collection of resources
  "message": "Success"       // Optional success message
}
```

For single resources (GET /events/{id}):
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

For collections (GET /events):
```json
[
  {
    "eventId": "abc-123",
    "title": "Event 1",
    ...
  },
  {
    "eventId": "def-456",
    "title": "Event 2",
    ...
  }
]
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

## Security Best Practices

- Validate and sanitize all inputs
- Use HTTPS in production
- Implement rate limiting
- Use authentication/authorization where needed
- Don't expose sensitive data in responses
- Use environment variables for secrets

## Testing Standards

- Test all endpoints with valid inputs
- Test error cases and edge cases
- Test validation rules
- Test authentication/authorization
- Use consistent test data
- Maintain high test coverage
