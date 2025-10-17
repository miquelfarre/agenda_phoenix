from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
from supabase import create_client, Client
from datetime import datetime
import logging
from init_db import init_database

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Agenda Phoenix API", version="1.0.0")


@app.on_event("startup")
async def startup_event():
    """
    Execute on application startup.
    Initialize database: drop all tables, recreate them, and insert sample data.
    """
    logger.info("🚀 FastAPI application starting up...")
    try:
        init_database()
        logger.info("✅ Database initialization completed")
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")
        # Don't prevent app from starting, but log the error
        # raise  # Uncomment if you want to prevent startup on DB error

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "http://localhost:8000")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# Models
class Event(BaseModel):
    id: Optional[int] = None
    name: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class EventCreate(BaseModel):
    name: str


# Routes
@app.get("/")
async def root():
    return {
        "message": "Agenda Phoenix API",
        "version": "1.0.0",
        "endpoints": {
            "events": "/events",
            "event_by_id": "/events/{id}",
            "health": "/health"
        }
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


@app.get("/events", response_model=List[Event])
async def get_events():
    """Get all events from Supabase"""
    try:
        response = supabase.table("events").select("*").execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching events: {str(e)}")


@app.get("/events/{event_id}", response_model=Event)
async def get_event(event_id: int):
    """Get a single event by ID"""
    try:
        response = supabase.table("events").select("*").eq("id", event_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Event not found")
        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching event: {str(e)}")


@app.post("/events", response_model=Event, status_code=201)
async def create_event(event: EventCreate):
    """Create a new event"""
    try:
        response = supabase.table("events").insert({"name": event.name}).execute()
        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create event")
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating event: {str(e)}")


@app.put("/events/{event_id}", response_model=Event)
async def update_event(event_id: int, event: EventCreate):
    """Update an existing event"""
    try:
        response = supabase.table("events").update({"name": event.name}).eq("id", event_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Event not found")
        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating event: {str(e)}")


@app.delete("/events/{event_id}")
async def delete_event(event_id: int):
    """Delete an event"""
    try:
        response = supabase.table("events").delete().eq("id", event_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Event not found")
        return {"message": "Event deleted successfully", "id": event_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting event: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
