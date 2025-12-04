# KiroWorkshop

A serverless Event Management API built with FastAPI, DynamoDB, and AWS CDK. This project demonstrates a complete serverless architecture with infrastructure as code, automated deployment, and full CRUD operations.

## Architecture

- **Backend**: FastAPI (Python) running on AWS Lambda
- **Database**: DynamoDB for scalable NoSQL storage
- **API Gateway**: RESTful API with CORS support
- **Infrastructure**: AWS CDK for infrastructure as code
- **Deployment**: Automated packaging and deployment scripts

## Deployed API

**Production URL**: https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/

## Features

- ✅ Full CRUD operations for events
- ✅ Custom or auto-generated event IDs
- ✅ Input validation with Pydantic
- ✅ CORS enabled for web access
- ✅ Comprehensive error handling
- ✅ Serverless architecture (pay-per-use)
- ✅ Infrastructure as code with CDK

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API information |
| GET | `/health` | Health check |
| POST | `/events` | Create a new event |
| GET | `/events` | List all events |
| GET | `/events/{id}` | Get event by ID |
| PUT | `/events/{id}` | Update an event |
| DELETE | `/events/{id}` | Delete an event |

## Event Schema

```json
{
  "eventId": "string (optional - auto-generated if not provided)",
  "title": "string (1-200 chars)",
  "description": "string (1-2000 chars)",
  "date": "string (ISO format: YYYY-MM-DD)",
  "location": "string (1-200 chars)",
  "capacity": "integer (1-100000)",
  "organizer": "string (1-200 chars)",
  "status": "active | cancelled | completed"
}
```

## Quick Start

### Prerequisites

- Python 3.11+
- Node.js (for CDK)
- AWS CLI configured
- AWS CDK CLI installed

### Local Development

```bash
# Install backend dependencies
cd backend
pip install -r requirements.txt

# Run locally (requires local DynamoDB or AWS credentials)
uvicorn main:app --reload
```

### Deploy to AWS

```bash
# Package Lambda function
./infrastructure/package_lambda.sh

# Deploy with CDK
cd infrastructure
cdk deploy
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

## Usage Examples

### Create an Event (Auto-generated ID)

```bash
curl -X POST https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "AWS Workshop",
    "description": "Learn about AWS services and best practices",
    "date": "2025-12-15",
    "location": "Seattle, WA",
    "capacity": 50,
    "organizer": "AWS Team",
    "status": "active"
  }'
```

### Create an Event (Custom ID)

```bash
curl -X POST https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "my-custom-event-123",
    "title": "Custom Event",
    "description": "Event with custom ID",
    "date": "2025-12-20",
    "location": "Online",
    "capacity": 100,
    "organizer": "Event Team",
    "status": "active"
  }'
```

### List All Events

```bash
curl https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events
```

### Get Event by ID

```bash
curl https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events/my-custom-event-123
```

### Update an Event

```bash
curl -X PUT https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events/my-custom-event-123 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Event Title",
    "status": "completed"
  }'
```

### Delete an Event

```bash
curl -X DELETE https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/events/my-custom-event-123
```

### Health Check

```bash
curl https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod/health
```

## Project Structure

```
.
├── backend/
│   ├── main.py              # FastAPI application
│   ├── models.py            # Pydantic models
│   ├── database.py          # DynamoDB client
│   ├── requirements.txt     # Python dependencies
│   └── README.md           # Backend documentation
├── infrastructure/
│   ├── app.py              # CDK app entry point
│   ├── stacks/
│   │   └── backend_stack.py # CDK stack definition
│   ├── package_lambda.sh   # Lambda packaging script
│   └── requirements.txt    # CDK dependencies
├── TESTING.md              # Testing guide
├── DEPLOYMENT.md           # Deployment guide
└── README.md              # This file
```

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing instructions including:
- Local testing
- API testing with curl
- Automated test scripts

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for step-by-step deployment instructions including:
- AWS prerequisites
- CDK bootstrapping
- Deployment process
- Troubleshooting

## Technologies Used

- **FastAPI**: Modern Python web framework
- **Pydantic**: Data validation
- **Boto3**: AWS SDK for Python
- **Mangum**: ASGI adapter for AWS Lambda
- **AWS Lambda**: Serverless compute
- **Amazon DynamoDB**: NoSQL database
- **Amazon API Gateway**: API management
- **AWS CDK**: Infrastructure as code
- **Python 3.11**: Programming language

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
