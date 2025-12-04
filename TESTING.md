# Testing Guide

## Option 1: Test Locally (No Deployment Required)

### Setup Local Environment

1. **Install Python dependencies:**
```bash
cd backend
pip install -r requirements.txt
```

2. **Set up local DynamoDB (optional - for full testing):**
```bash
# Using Docker
docker run -p 8000:8000 amazon/dynamodb-local

# Or use DynamoDB in AWS (set environment variable)
export DYNAMODB_TABLE_NAME=Events
export AWS_DEFAULT_REGION=us-west-2
```

3. **Run the API locally:**
```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

4. **Access the API:**
- API: http://localhost:8000
- Interactive Docs: http://localhost:8000/docs
- Alternative Docs: http://localhost:8000/redoc

### Run Test Script

```bash
./test_api.sh http://localhost:8000
```

### Manual Testing with curl

```bash
# Health check
curl http://localhost:8000/health

# Create an event
curl -X POST http://localhost:8000/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tech Conference 2025",
    "description": "Annual technology conference",
    "date": "2025-06-15",
    "location": "San Francisco, CA",
    "capacity": 500,
    "organizer": "Tech Corp",
    "status": "active"
  }'

# List all events
curl http://localhost:8000/events

# Get specific event (replace {eventId} with actual ID)
curl http://localhost:8000/events/{eventId}

# Update event
curl -X PUT http://localhost:8000/events/{eventId} \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'

# Delete event
curl -X DELETE http://localhost:8000/events/{eventId}
```

## Option 2: Test Deployed API

### Deploy the API

Follow the [DEPLOYMENT.md](DEPLOYMENT.md) guide to deploy the API to AWS.

After deployment, you'll get a public URL like:
```
https://xxxxxxxxxx.execute-api.us-west-2.amazonaws.com/prod/
```

### Test the Deployed API

```bash
# Set your API URL
export API_URL="https://your-api-id.execute-api.us-west-2.amazonaws.com/prod"

# Run the test script
./test_api.sh $API_URL
```

## Using Postman or Thunder Client

1. Import the API from the OpenAPI spec at: `http://localhost:8000/openapi.json`
2. Or manually create requests for each endpoint:
   - POST /events
   - GET /events
   - GET /events/{eventId}
   - PUT /events/{eventId}
   - DELETE /events/{eventId}

## Sample Event Data

```json
{
  "title": "AWS re:Invent 2025",
  "description": "AWS annual conference for cloud computing",
  "date": "2025-11-30",
  "location": "Las Vegas, NV",
  "capacity": 50000,
  "organizer": "Amazon Web Services",
  "status": "active"
}
```

## Expected Responses

### Success Responses

- **POST /events**: Returns created event with `eventId` (201 Created)
- **GET /events**: Returns array of all events (200 OK)
- **GET /events/{eventId}**: Returns single event (200 OK)
- **PUT /events/{eventId}**: Returns updated event (200 OK)
- **DELETE /events/{eventId}**: Returns empty response (204 No Content)

### Error Responses

- **404 Not Found**: Event doesn't exist
- **422 Unprocessable Entity**: Invalid input data
- **500 Internal Server Error**: Server error

## Validation Rules

- **title**: 1-200 characters
- **description**: 1-2000 characters
- **date**: ISO format (YYYY-MM-DD)
- **location**: 1-200 characters
- **capacity**: 1-100,000
- **organizer**: 1-200 characters
- **status**: "active", "cancelled", or "completed"
