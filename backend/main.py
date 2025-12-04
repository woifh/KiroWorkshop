from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from typing import List
from datetime import datetime
import uuid
import re
from models import (
    Event, EventCreate, EventUpdate,
    User, UserCreate,
    Registration, RegistrationCreate, RegistrationResponse,
    UserRegistrationDetail
)
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


# User endpoints
@app.post("/users", response_model=User, status_code=201)
def create_user(user: UserCreate):
    try:
        logger.info(f"Creating user: {user.name}")
        return db.create_user(user)
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create user")


@app.get("/users/{user_id}", response_model=User)
def get_user(user_id: str):
    try:
        logger.info(f"Getting user: {user_id}")
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve user")


@app.get("/users", response_model=List[User])
def list_users():
    try:
        logger.info("Listing all users")
        return db.list_users()
    except Exception as e:
        logger.error(f"Error listing users: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve users")


# Registration endpoints
def validate_id(value: str, field_name: str):
    # Allow both UUID format and custom string IDs (alphanumeric with hyphens)
    # UUID pattern or custom ID pattern (letters, numbers, hyphens, underscores)
    uuid_pattern = re.compile(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        re.IGNORECASE
    )
    custom_id_pattern = re.compile(r'^[a-zA-Z0-9_-]+$')
    
    if not (uuid_pattern.match(value) or custom_id_pattern.match(value)):
        raise HTTPException(
            status_code=422,
            detail=f"Invalid {field_name}: must be a valid UUID or alphanumeric ID"
        )


@app.post("/events/{event_id}/registrations", response_model=RegistrationResponse, status_code=201)
def register_for_event(event_id: str, registration: RegistrationCreate):
    try:
        user_id = registration.userId
        validate_id(user_id, "userId")
        validate_id(event_id, "eventId")
        
        logger.info(f"User {user_id} registering for event {event_id}")
        
        # Check if user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if event exists
        event = db.get_event(event_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        
        # Check if user is already registered or waitlisted
        existing_registration = db.get_registration(user_id, event_id)
        if existing_registration:
            if existing_registration.status == "registered":
                raise HTTPException(
                    status_code=409,
                    detail="User is already registered for this event"
                )
            else:
                raise HTTPException(
                    status_code=409,
                    detail=f"User is already on the waitlist at position {existing_registration.waitlistPosition}"
                )
        
        # Check capacity
        if event.registeredCount < event.capacity:
            # Register user
            registration_id = str(uuid.uuid4())
            registered_at = datetime.utcnow().isoformat() + 'Z'
            new_registration = Registration(
                registrationId=registration_id,
                userId=user_id,
                eventId=event_id,
                status="registered",
                registeredAt=registered_at,
                waitlistPosition=None
            )
            db.create_registration(new_registration)
            db.increment_event_count(event_id, 'registeredCount', 1)
            
            logger.info(f"User {user_id} successfully registered for event {event_id}")
            return RegistrationResponse(
                registrationId=registration_id,
                userId=user_id,
                eventId=event_id,
                status="registered",
                registeredAt=registered_at,
                waitlistPosition=None,
                message="Successfully registered for event"
            )
        else:
            # Event is full
            if event.hasWaitlist:
                # Add to waitlist
                registration_id = str(uuid.uuid4())
                registered_at = datetime.utcnow().isoformat() + 'Z'
                waitlist_position = event.waitlistCount + 1
                
                new_registration = Registration(
                    registrationId=registration_id,
                    userId=user_id,
                    eventId=event_id,
                    status="waitlisted",
                    registeredAt=registered_at,
                    waitlistPosition=waitlist_position
                )
                db.create_registration(new_registration)
                db.increment_event_count(event_id, 'waitlistCount', 1)
                
                logger.info(f"User {user_id} added to waitlist for event {event_id} at position {waitlist_position}")
                return RegistrationResponse(
                    registrationId=registration_id,
                    userId=user_id,
                    eventId=event_id,
                    status="waitlisted",
                    registeredAt=registered_at,
                    waitlistPosition=waitlist_position,
                    message=f"Event is full. Added to waitlist at position {waitlist_position}"
                )
            else:
                # No waitlist, reject
                logger.info(f"Registration denied for user {user_id} - event {event_id} is full")
                raise HTTPException(
                    status_code=409,
                    detail=f"Event is at full capacity ({event.capacity}/{event.capacity}). No waitlist available."
                )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error registering for event: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to register for event")


@app.delete("/events/{event_id}/registrations/{user_id}", status_code=200)
def unregister_from_event(event_id: str, user_id: str):
    try:
        validate_id(user_id, "userId")
        validate_id(event_id, "eventId")
        
        logger.info(f"User {user_id} unregistering from event {event_id}")
        
        # Check if registration exists
        registration = db.get_registration(user_id, event_id)
        if not registration:
            raise HTTPException(
                status_code=404,
                detail="Registration not found"
            )
        
        # Get event
        event = db.get_event(event_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        
        # Delete registration
        db.delete_registration(registration.registrationId)
        
        if registration.status == "registered":
            db.increment_event_count(event_id, 'registeredCount', -1)
            
            # Check if there's a waitlist to promote
            if event.hasWaitlist and event.waitlistCount > 0:
                waitlist_users = db.get_waitlist_users(event_id)
                if waitlist_users:
                    # Promote first user from waitlist
                    first_waitlisted = waitlist_users[0]
                    
                    # Delete old waitlist registration
                    db.delete_registration(first_waitlisted.registrationId)
                    
                    # Create new registered registration
                    new_registration_id = str(uuid.uuid4())
                    promoted_registration = Registration(
                        registrationId=new_registration_id,
                        userId=first_waitlisted.userId,
                        eventId=event_id,
                        status="registered",
                        registeredAt=datetime.utcnow().isoformat() + 'Z',
                        waitlistPosition=None
                    )
                    db.create_registration(promoted_registration)
                    
                    # Update counts
                    db.increment_event_count(event_id, 'registeredCount', 1)
                    db.increment_event_count(event_id, 'waitlistCount', -1)
                    
                    logger.info(f"Promoted user {first_waitlisted.userId} from waitlist to registered")
                    
                    return {
                        "message": "Successfully unregistered from event",
                        "promotedUser": first_waitlisted.userId
                    }
            
            logger.info(f"User {user_id} successfully unregistered from event {event_id}")
            return {"message": "Successfully unregistered from event"}
        
        else:  # waitlisted
            db.increment_event_count(event_id, 'waitlistCount', -1)
            logger.info(f"User {user_id} removed from waitlist for event {event_id}")
            return {"message": "Successfully removed from waitlist"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error unregistering from event: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to unregister from event")


@app.get("/events/{event_id}/registrations")
def get_event_registrations(event_id: str):
    try:
        validate_id(event_id, "eventId")
        
        logger.info(f"Getting registrations for event {event_id}")
        
        # Check if event exists
        event = db.get_event(event_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        
        # Get all registrations for event
        registrations = db.get_event_registrations(event_id)
        
        logger.info(f"Found {len(registrations)} registrations for event {event_id}")
        return registrations
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting event registrations: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve event registrations")


@app.get("/users/{user_id}/registrations", response_model=List[UserRegistrationDetail])
def get_user_registrations(user_id: str):
    try:
        validate_id(user_id, "userId")
        
        logger.info(f"Getting registrations for user {user_id}")
        
        # Check if user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Get all registrations for user
        registrations = db.get_user_registrations(user_id)
        
        # Get event details for each registration
        result = []
        for reg in registrations:
            event = db.get_event(reg.eventId)
            if event:
                result.append(UserRegistrationDetail(
                    registration=reg,
                    event=event
                ))
        
        # Sort by event date
        result.sort(key=lambda x: x.event.date)
        
        logger.info(f"Found {len(result)} registrations for user {user_id}")
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user registrations: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve user registrations")


# Lambda handler
from mangum import Mangum
handler = Mangum(app)
