# Backend

FastAPI Python backend application for managing events.

## Setup

```bash
pip install -r requirements.txt
```

## Environment Variables

```bash
export DYNAMODB_TABLE_NAME=Events
export AWS_DEFAULT_REGION=us-west-2
```

## Run

```bash
uvicorn main:app --reload
```

API will be available at http://localhost:8000

## API Endpoints

- `POST /events` - Create a new event
- `GET /events` - List all events
- `GET /events/{event_id}` - Get a specific event
- `PUT /events/{event_id}` - Update an event
- `DELETE /events/{event_id}` - Delete an event
- `GET /health` - Health check

Interactive API docs: http://localhost:8000/docs
