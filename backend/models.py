from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal
from datetime import datetime


class Event(BaseModel):
    eventId: str = Field(..., description="Unique event identifier")
    title: str = Field(..., min_length=1, max_length=200, description="Event title")
    description: str = Field(..., min_length=1, max_length=2000, description="Event description")
    date: str = Field(..., description="Event date in ISO format")
    location: str = Field(..., min_length=1, max_length=200, description="Event location")
    capacity: int = Field(..., gt=0, le=100000, description="Event capacity")
    hasWaitlist: bool = Field(default=False, description="Enable waitlist when full")
    registeredCount: int = Field(default=0, description="Current registration count")
    waitlistCount: int = Field(default=0, description="Current waitlist count")
    organizer: str = Field(..., min_length=1, max_length=200, description="Event organizer")
    status: Literal["active", "cancelled", "completed"] = Field(..., description="Event status")


class EventCreate(BaseModel):
    eventId: Optional[str] = Field(None, description="Optional custom event identifier")
    title: str = Field(..., min_length=1, max_length=200, description="Event title")
    description: str = Field(..., min_length=1, max_length=2000, description="Event description")
    date: str = Field(..., description="Event date in ISO format (YYYY-MM-DD)")
    location: str = Field(..., min_length=1, max_length=200, description="Event location")
    capacity: int = Field(..., gt=0, le=100000, description="Event capacity (1-100000)")
    hasWaitlist: bool = Field(default=False, description="Enable waitlist when full")
    organizer: str = Field(..., min_length=1, max_length=200, description="Event organizer")
    status: Literal["active", "cancelled", "completed"] = Field(default="active", description="Event status")

    @field_validator('date')
    @classmethod
    def validate_date(cls, v: str) -> str:
        try:
            datetime.fromisoformat(v)
            return v
        except ValueError:
            raise ValueError('Date must be in ISO format (YYYY-MM-DD)')


class EventUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200, description="Event title")
    description: Optional[str] = Field(None, min_length=1, max_length=2000, description="Event description")
    date: Optional[str] = Field(None, description="Event date in ISO format (YYYY-MM-DD)")
    location: Optional[str] = Field(None, min_length=1, max_length=200, description="Event location")
    capacity: Optional[int] = Field(None, gt=0, le=100000, description="Event capacity (1-100000)")
    hasWaitlist: Optional[bool] = Field(None, description="Enable waitlist when full")
    organizer: Optional[str] = Field(None, min_length=1, max_length=200, description="Event organizer")
    status: Optional[Literal["active", "cancelled", "completed"]] = Field(None, description="Event status")

    @field_validator('date')
    @classmethod
    def validate_date(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            try:
                datetime.fromisoformat(v)
                return v
            except ValueError:
                raise ValueError('Date must be in ISO format (YYYY-MM-DD)')
        return v


# User models
class User(BaseModel):
    userId: str = Field(..., description="Unique user identifier (UUID)")
    name: str = Field(..., min_length=1, max_length=200, description="User's name")
    createdAt: str = Field(..., description="ISO 8601 timestamp")


class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200, description="User's name")


# Registration models
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


class UserRegistrationDetail(BaseModel):
    registration: Registration
    event: Event
