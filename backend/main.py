"""
Agenda Phoenix API

Modular FastAPI application using routers for organized endpoint management.
"""

import logging
from contextlib import asynccontextmanager
from datetime import datetime

import uvicorn
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from init_db_2 import init_database

# Import all routers
from routers import calendar_memberships, calendars, event_memberships, events, group_memberships, groups, interactions, user_blocks, user_contacts, users

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global flag to track database initialization
_db_initialized = False


# Lifespan event handler
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Execute on application startup and shutdown.
    Initialize database: drop all tables, recreate them, and insert sample data.
    """
    global _db_initialized
    # Startup
    logger.info("🚀 FastAPI application starting up...")
    try:
        init_database()
        _db_initialized = True
        logger.info("✅ Database initialization completed")
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")

    yield  # Application is running

    # Shutdown
    logger.info("👋 FastAPI application shutting down...")


# Initialize FastAPI app with lifespan
app = FastAPI(title="Agenda Phoenix API", version="2.0.0", description="Calendar and Event Management API with modular router structure", lifespan=lifespan)


# Exception handler for validation errors
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Log validation errors with request body for debugging"""
    # Try to read the body
    try:
        body = await request.body()
        body_str = body.decode('utf-8')
        logger.error(f"❌ [VALIDATION ERROR] Path: {request.url.path}")
        logger.error(f"❌ [VALIDATION ERROR] Raw body: {body_str}")
        logger.error(f"❌ [VALIDATION ERROR] Errors: {exc.errors()}")
    except Exception as e:
        logger.error(f"❌ [VALIDATION ERROR] Could not read body: {e}")
        logger.error(f"❌ [VALIDATION ERROR] Errors: {exc.errors()}")

    # Return the standard FastAPI validation error response
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()},
    )


# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Register all routers
app.include_router(users.router)
app.include_router(events.router)
app.include_router(event_memberships.router)
app.include_router(interactions.router)
app.include_router(calendars.router)
app.include_router(calendar_memberships.router)
app.include_router(groups.router)
app.include_router(group_memberships.router)
app.include_router(user_blocks.router)
app.include_router(user_contacts.router)


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
            "user_blocks": "/user_blocks",
        },
        "docs": "/docs",
        "health": "/health",
    }


# Health check endpoint
@app.get("/health")
async def health():
    """
    Health check endpoint.
    Returns 200 only after database initialization is complete.
    This ensures PostgREST waits for all tables and views to be created.
    """
    if not _db_initialized:
        raise HTTPException(status_code=503, detail="Database initialization in progress")
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
