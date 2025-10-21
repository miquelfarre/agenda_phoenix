"""
Agenda Phoenix API

Modular FastAPI application using routers for organized endpoint management.
"""

import logging
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from init_db import init_database

# Import all routers
from routers import app_bans, calendar_memberships, calendars, contacts, event_bans, events, group_memberships, groups, interactions, recurring_configs, user_blocks, users

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Lifespan event handler
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Execute on application startup and shutdown.
    Initialize database: drop all tables, recreate them, and insert sample data.
    """
    # Startup
    logger.info("🚀 FastAPI application starting up...")
    try:
        init_database()
        logger.info("✅ Database initialization completed")
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")

    yield  # Application is running

    # Shutdown
    logger.info("👋 FastAPI application shutting down...")


# Initialize FastAPI app with lifespan
app = FastAPI(title="Agenda Phoenix API", version="2.0.0", description="Calendar and Event Management API with modular router structure", lifespan=lifespan)


# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Register all routers
app.include_router(contacts.router)
app.include_router(users.router)
app.include_router(events.router)
app.include_router(interactions.router)
app.include_router(calendars.router)
app.include_router(calendar_memberships.router)
app.include_router(groups.router)
app.include_router(group_memberships.router)
app.include_router(recurring_configs.router)
app.include_router(event_bans.router)
app.include_router(user_blocks.router)
app.include_router(app_bans.router)


# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "name": "Agenda Phoenix API",
        "version": "2.0.0",
        "status": "running",
        "description": "Calendar and Event Management API",
        "architecture": "Modular with FastAPI Routers",
        "endpoints": {
            "contacts": "/contacts",
            "users": "/users",
            "events": "/events",
            "interactions": "/interactions",
            "calendars": "/calendars",
            "calendar_memberships": "/calendar_memberships",
            "groups": "/groups",
            "group_memberships": "/group_memberships",
            "recurring_configs": "/recurring_configs",
            "event_bans": "/event_bans",
            "user_blocks": "/user_blocks",
            "app_bans": "/app_bans",
        },
        "docs": "/docs",
        "health": "/health",
    }


# Health check endpoint
@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
