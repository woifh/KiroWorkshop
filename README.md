# KiroWorkshop

Event Management API built with FastAPI, DynamoDB, and AWS CDK.

## Deployed API

**API URL**: https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/

## Quick Test

```bash
# Health check
curl https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/health

# Create an event
curl -X POST https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "AWS Workshop",
    "description": "Learn about AWS services",
    "date": "2025-12-15",
    "location": "Seattle, WA",
    "capacity": 50,
    "organizer": "AWS Team",
    "status": "active"
  }'

# List all events
curl https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events
```

## Project Structure

- `backend/` - FastAPI application with DynamoDB integration
- `infrastructure/` - AWS CDK infrastructure code
- `TESTING.md` - Detailed testing instructions
- `DEPLOYMENT.md` - Deployment guide
