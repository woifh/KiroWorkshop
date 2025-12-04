from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from typing import List
from models import Event, EventCreate, EventUpdate
from database import DynamoDBClient
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Events API",
    description="REST API for managing events with DynamoDB",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

db = DynamoDBClient()


# Global exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.error(f"Validation error: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors(), "message": "Invalid input data"}
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unexpected error: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error", "message": str(exc)}
    )


@app.get("/")
def read_root():
    return {"message": "Events API", "version": "1.0.0"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.post("/events", response_model=Event, status_code=201)
def create_event(event: EventCreate):
    try:
        logger.info(f"Creating event: {event.title}")
        return db.create_event(event)
    except Exception as e:
        logger.error(f"Error creating event: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create event")


@app.get("/events", response_model=List[Event])
def list_events():
    try:
        logger.info("Listing all events")
        return db.list_events()
    except Exception as e:
        logger.error(f"Error listing events: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve events")


@app.get("/events/{event_id}", response_model=Event)
def get_event(event_id: str):
    try:
        logger.info(f"Getting event: {event_id}")
        event = db.get_event(event_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        return event
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting event: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve event")


@app.put("/events/{event_id}", response_model=Event)
def update_event(event_id: str, event_update: EventUpdate):
    try:
        logger.info(f"Updating event: {event_id}")
        event = db.update_event(event_id, event_update)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        return event
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating event: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update event")


@app.delete("/events/{event_id}", status_code=204)
def delete_event(event_id: str):
    try:
        logger.info(f"Deleting event: {event_id}")
        success = db.delete_event(event_id)
        if not success:
            raise HTTPException(status_code=404, detail="Event not found")
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting event: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to delete event")

# Lambda handler
from mangum import Mangum
handler = Mangum(app)
