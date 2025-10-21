"""
API Configuration - Centralized endpoint management

All API endpoints are defined here as constants and helper functions.
This ensures consistency and makes it easy to update endpoints.
"""

import os

# API Base URL - can be overridden with AGENDA_API_URL environment variable
API_BASE_URL = os.getenv("AGENDA_API_URL", "http://localhost:8001")


# ============================================================================
# ROOT & HEALTH
# ============================================================================


def url_root():
    """GET / - Root endpoint"""
    return f"{API_BASE_URL}/"


def url_health():
    """GET /health - Health check"""
    return f"{API_BASE_URL}/health"


# ============================================================================
# CONTACTS
# ============================================================================


def url_contacts():
    """GET/POST /contacts - List all contacts / Create contact"""
    return f"{API_BASE_URL}/contacts"


def url_contact(contact_id):
    """GET/PUT/DELETE /contacts/{contact_id} - Single contact operations"""
    return f"{API_BASE_URL}/contacts/{contact_id}"


# ============================================================================
# USERS
# ============================================================================


def url_users():
    """GET/POST /users - List all users / Create user"""
    return f"{API_BASE_URL}/users"


def url_user(user_id):
    """GET/PUT/DELETE /users/{user_id} - Single user operations"""
    return f"{API_BASE_URL}/users/{user_id}"


def url_user_events(user_id):
    """GET /users/{user_id}/events - Get all events for user"""
    return f"{API_BASE_URL}/users/{user_id}/events"


def url_user_subscribe(user_id, target_user_id):
    """POST /users/{user_id}/subscribe/{target_user_id} - Subscribe to user's events"""
    return f"{API_BASE_URL}/users/{user_id}/subscribe/{target_user_id}"


# ============================================================================
# EVENTS
# ============================================================================


def url_events():
    """GET/POST /events - List all events / Create event"""
    return f"{API_BASE_URL}/events"


def url_event(event_id):
    """GET/PUT/DELETE /events/{event_id} - Single event operations"""
    return f"{API_BASE_URL}/events/{event_id}"


def url_event_interactions(event_id):
    """GET /events/{event_id}/interactions - Get event interactions"""
    return f"{API_BASE_URL}/events/{event_id}/interactions"


def url_event_interactions_enriched(event_id):
    """GET /events/{event_id}/interactions-enriched - Get event interactions with user info"""
    return f"{API_BASE_URL}/events/{event_id}/interactions-enriched"


def url_event_available_invitees(event_id):
    """GET /events/{event_id}/available-invitees - Get users available to invite"""
    return f"{API_BASE_URL}/events/{event_id}/available-invitees"


def url_event_cancellations():
    """GET /events/cancellations - Get event cancellations for a user"""
    return f"{API_BASE_URL}/events/cancellations"


def url_event_cancellation_view(cancellation_id):
    """POST /events/cancellations/{cancellation_id}/view - Mark cancellation as viewed"""
    return f"{API_BASE_URL}/events/cancellations/{cancellation_id}/view"


# ============================================================================
# INTERACTIONS
# ============================================================================


def url_interactions():
    """GET/POST /interactions - List interactions / Create interaction"""
    return f"{API_BASE_URL}/interactions"


def url_interaction(interaction_id):
    """GET/PUT/PATCH/DELETE /interactions/{interaction_id} - Single interaction operations"""
    return f"{API_BASE_URL}/interactions/{interaction_id}"


# ============================================================================
# CALENDARS
# ============================================================================


def url_calendars():
    """GET/POST /calendars - List all calendars / Create calendar"""
    return f"{API_BASE_URL}/calendars"


def url_calendar(calendar_id):
    """GET/PUT/DELETE /calendars/{calendar_id} - Single calendar operations"""
    return f"{API_BASE_URL}/calendars/{calendar_id}"


def url_calendar_memberships_nested(calendar_id):
    """GET /calendars/{calendar_id}/memberships - Get calendar members"""
    return f"{API_BASE_URL}/calendars/{calendar_id}/memberships"


def url_calendars_memberships_create():
    """POST /calendars/memberships - Create calendar membership (alias endpoint)"""
    return f"{API_BASE_URL}/calendars/memberships"


# ============================================================================
# CALENDAR MEMBERSHIPS
# ============================================================================


def url_calendar_memberships():
    """GET/POST /calendar_memberships - List memberships / Create membership"""
    return f"{API_BASE_URL}/calendar_memberships"


def url_calendar_membership(membership_id):
    """GET/PUT/DELETE /calendar_memberships/{membership_id} - Single membership operations"""
    return f"{API_BASE_URL}/calendar_memberships/{membership_id}"


# ============================================================================
# GROUPS
# ============================================================================


def url_groups():
    """GET/POST /groups - List all groups / Create group"""
    return f"{API_BASE_URL}/groups"


def url_group(group_id):
    """GET/PUT/DELETE /groups/{group_id} - Single group operations"""
    return f"{API_BASE_URL}/groups/{group_id}"


# ============================================================================
# GROUP MEMBERSHIPS
# ============================================================================


def url_group_memberships():
    """GET/POST /group_memberships - List memberships / Create membership"""
    return f"{API_BASE_URL}/group_memberships"


def url_group_membership(membership_id):
    """GET/DELETE /group_memberships/{membership_id} - Single membership operations"""
    return f"{API_BASE_URL}/group_memberships/{membership_id}"


# ============================================================================
# RECURRING CONFIGS
# ============================================================================


def url_recurring_configs():
    """GET/POST /recurring_configs - List configs / Create config"""
    return f"{API_BASE_URL}/recurring_configs"


def url_recurring_config(config_id):
    """GET/PUT/DELETE /recurring_configs/{config_id} - Single config operations"""
    return f"{API_BASE_URL}/recurring_configs/{config_id}"


# ============================================================================
# EVENT BANS
# ============================================================================


def url_event_bans():
    """GET/POST /event_bans - List bans / Create ban"""
    return f"{API_BASE_URL}/event_bans"


def url_event_ban(ban_id):
    """GET/DELETE /event_bans/{ban_id} - Single ban operations"""
    return f"{API_BASE_URL}/event_bans/{ban_id}"


# ============================================================================
# USER BLOCKS
# ============================================================================


def url_user_blocks():
    """GET/POST /user_blocks - List blocks / Create block"""
    return f"{API_BASE_URL}/user_blocks"


def url_user_block(block_id):
    """GET/DELETE /user_blocks/{block_id} - Single block operations"""
    return f"{API_BASE_URL}/user_blocks/{block_id}"


# ============================================================================
# APP BANS
# ============================================================================


def url_app_bans():
    """GET/POST /app_bans - List app bans / Create app ban (admin only)"""
    return f"{API_BASE_URL}/app_bans"


def url_app_ban(ban_id):
    """GET/DELETE /app_bans/{ban_id} - Single app ban operations (admin only)"""
    return f"{API_BASE_URL}/app_bans/{ban_id}"


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


def build_query_params(**kwargs):
    """
    Build query string from keyword arguments.

    Example:
        build_query_params(user_id=1, status='pending')
        Returns: "?user_id=1&status=pending"
    """
    params = "&".join([f"{k}={v}" for k, v in kwargs.items() if v is not None])
    return f"?{params}" if params else ""


# ============================================================================
# VALIDATION
# ============================================================================


def validate_endpoint_exists():
    """
    Validate that the backend is running and accessible.
    Returns True if backend is up, False otherwise.
    """
    import requests

    try:
        response = requests.get(url_health(), timeout=2)
        return response.status_code == 200
    except:
        return False
