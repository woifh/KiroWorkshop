from fastapi import FastAPI, HTTPException
from typing import List
from models import Event, EventCreate, EventUpdate
from database import DynamoDBClient

app = FastAPI(title="Events API")
db = DynamoDBClient()


@app.get("/")
def read_root():
    return {"message": "Events API"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.post("/events", response_model=Event, status_code=201)
def create_event(event: EventCreate):
    return db.create_event(event)


@app.get("/events", response_model=List[Event])
def list_events():
    return db.list_events()


@app.get("/events/{event_id}", response_model=Event)
def get_event(event_id: str):
    event = db.get_event(event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event


@app.put("/events/{event_id}", response_model=Event)
def update_event(event_id: str, event_update: EventUpdate):
    event = db.update_event(event_id, event_update)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event


@app.delete("/events/{event_id}", status_code=204)
def delete_event(event_id: str):
    success = db.delete_event(event_id)
    if not success:
        raise HTTPException(status_code=404, detail="Event not found")
    return None
