"""
Utility functions for common operations
"""

from datetime import datetime
from typing import Optional, Tuple
from fastapi import HTTPException


def round_to_5min(dt: Optional[datetime]) -> Optional[datetime]:
    """
    Round datetime to nearest 5-minute interval.

    Examples:
        - 14:32:45 -> 14:30:00
        - 14:37:45 -> 14:35:00
        - 14:33:00 -> 14:30:00

    Args:
        dt: Datetime to round. If None, returns None.

    Returns:
        Rounded datetime with seconds and microseconds set to 0,
        or None if input is None.
    """
    if not dt:
        return None
    minute = (dt.minute // 5) * 5
    return dt.replace(minute=minute, second=0, microsecond=0)


def validate_5min_interval(minute: int) -> bool:
    """
    Validate that a minute value is in 5-minute intervals.

    Args:
        minute: Minute value (0-59)

    Returns:
        True if minute is valid (0, 5, 10, ..., 55), False otherwise.
    """
    return minute % 5 == 0


def validate_pagination(limit: int, offset: int) -> Tuple[int, int]:
    """
    Validate and limit pagination parameters.

    Args:
        limit: Maximum number of items to return
        offset: Number of items to skip

    Returns:
        Tuple of (validated_limit, validated_offset)
        - limit is clamped between 1 and 200
        - offset is clamped to minimum 0
    """
    limit = max(1, min(200, limit))
    offset = max(0, offset)
    return limit, offset


def handle_crud_error(error: str, error_detail: Optional[str] = None) -> None:
    """
    Handle CRUD operation errors by raising appropriate HTTPException.

    This centralizes error handling logic used across multiple routers
    when CRUD operations return error messages.

    Args:
        error: Error message from CRUD operation
        error_detail: Optional detailed error information

    Raises:
        HTTPException with appropriate status code:
        - 404 if "not found" in error
        - 403 if "banned" in error
        - 409 if "already subscribed" in error
        - 400 for all other errors
    """
    error_lower = error.lower()

    if "not found" in error_lower:
        raise HTTPException(status_code=404, detail=error)
    elif "banned" in error_lower:
        raise HTTPException(
            status_code=403,
            detail=error_detail if error_detail else error
        )
    elif "already subscribed" in error_lower:
        raise HTTPException(status_code=409, detail=error)
    else:
        raise HTTPException(status_code=400, detail=error)
