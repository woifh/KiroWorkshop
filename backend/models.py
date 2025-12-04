from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class Event(BaseModel):
    eventId: str
    title: str
    description: str
    date: str
    location: str
    capacity: int
    organizer: str
    status: str


class EventCreate(BaseModel):
    title: str
    description: str
    date: str
    location: str
    capacity: int
    organizer: str
    status: str = "active"


class EventUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    date: Optional[str] = None
    location: Optional[str] = None
    capacity: Optional[int] = None
    organizer: Optional[str] = None
    status: Optional[str] = None
