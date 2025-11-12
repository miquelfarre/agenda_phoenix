"""
Utility functions for common operations
"""

from datetime import datetime
from typing import Optional


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
