# Deployment Guide

## Prerequisites

1. AWS CLI configured with credentials
2. CDK CLI installed (`npm install -g aws-cdk`)
3. Python 3.11+ installed
4. Docker installed (for Lambda container image)

## Deployment Steps

### 1. Install Infrastructure Dependencies

```bash
cd infrastructure
python3 -m pip install -r requirements.txt
```

### 2. Bootstrap CDK (first time only)

```bash
export AWS_DEFAULT_REGION=us-west-2
cdk bootstrap --no-verify-ssl
```

### 3. Deploy the Stack

```bash
cdk deploy --no-verify-ssl --require-approval never
```

This will create:
- DynamoDB table named "Events"
- Lambda function with FastAPI backend
- API Gateway with public endpoint
- All necessary IAM roles and permissions

### 4. Get the API URL

After deployment, the API URL will be displayed in the outputs:
```
Outputs:
BackendStack.ApiUrl = https://xxxxxxxxxx.execute-api.us-west-2.amazonaws.com/prod/
```

## Testing the API

Once deployed, you can test the endpoints:

```bash
# Health check
curl https://YOUR_API_URL/health

# Create an event
curl -X POST https://YOUR_API_URL/events \
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
curl https://YOUR_API_URL/events

# Get specific event
curl https://YOUR_API_URL/events/{eventId}

# Update event
curl -X PUT https://YOUR_API_URL/events/{eventId} \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'

# Delete event
curl -X DELETE https://YOUR_API_URL/events/{eventId}
```

## API Documentation

Interactive API documentation is available at:
- Swagger UI: `https://YOUR_API_URL/docs`
- ReDoc: `https://YOUR_API_URL/redoc`

## Cleanup

To remove all resources:

```bash
cd infrastructure
cdk destroy --no-verify-ssl
```

## Architecture

- **API Gateway**: Public REST API endpoint with CORS enabled
- **Lambda**: Docker container running FastAPI application
- **DynamoDB**: NoSQL database for event storage (pay-per-request billing)
- **IAM**: Least-privilege roles for Lambda to access DynamoDB

## Cost Optimization

- Lambda: Pay only for compute time (512MB memory, 30s timeout)
- DynamoDB: Pay-per-request billing (no provisioned capacity)
- API Gateway: Pay per request
- Estimated cost: < $1/month for low traffic
