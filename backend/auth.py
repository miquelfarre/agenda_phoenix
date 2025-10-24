"""
Authentication module for JWT validation with Supabase.

This module provides:
1. JWT validation using Supabase's public keys
2. User extraction from validated tokens
3. FastAPI dependency for protected endpoints
4. Test mode authentication via X-Test-User-Id header (development only)
"""

import os
from typing import Optional

import httpx
from fastapi import Depends, Header, HTTPException, status, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

# Security scheme for JWT Bearer tokens
security = HTTPBearer(auto_error=False)

# Cache for JWKS (JSON Web Key Set)
_jwks_cache: Optional[dict] = None


def get_supabase_jwks() -> dict:
    """
    Fetch Supabase JWKS (JSON Web Key Set) for JWT validation.

    Caches the result to avoid repeated HTTP calls.
    JWKS contains the public keys used to verify JWT signatures.
    """
    global _jwks_cache

    if _jwks_cache is not None:
        return _jwks_cache

    supabase_url = os.getenv("SUPABASE_URL")
    if not supabase_url:
        raise ValueError("SUPABASE_URL environment variable not set")

    # Fetch JWKS from Supabase
    jwks_url = f"{supabase_url}/auth/v1/jwks"

    try:
        response = httpx.get(jwks_url, timeout=10.0)
        response.raise_for_status()
        _jwks_cache = response.json()
        return _jwks_cache
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Failed to fetch Supabase JWKS: {str(e)}",
        )


def verify_jwt_token(token: str) -> dict:
    """
    Verify and decode a Supabase JWT token.

    Args:
        token: JWT token string from Authorization header

    Returns:
        Decoded JWT payload containing user information

    Raises:
        HTTPException: If token is invalid or expired
    """
    try:
        # Get Supabase JWKS
        jwks = get_supabase_jwks()

        # Decode token header to get key ID (kid)
        unverified_header = jwt.get_unverified_header(token)
        kid = unverified_header.get("kid")

        if not kid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: missing key ID",
            )

        # Find the matching public key from JWKS
        key = None
        for jwk_key in jwks.get("keys", []):
            if jwk_key.get("kid") == kid:
                key = jwk_key
                break

        if not key:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: key not found in JWKS",
            )

        # Verify and decode the token
        supabase_url = os.getenv("SUPABASE_URL")
        payload = jwt.decode(
            token,
            key,
            algorithms=["RS256"],
            audience="authenticated",  # Supabase default audience
            issuer=f"{supabase_url}/auth/v1",
        )

        return payload

    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    x_test_user_id: Optional[str] = Header(None),
) -> dict:
    """
    FastAPI dependency to extract and validate current user from JWT.

    In development mode (ENVIRONMENT != production), supports X-Test-User-Id header
    for testing without real JWT tokens.

    Usage in endpoints:
    ```python
    @router.get("/protected")
    async def protected_route(current_user: dict = Depends(get_current_user)):
        user_id = current_user["sub"]  # User ID from token
        # ... endpoint logic
    ```

    Returns:
        dict: JWT payload containing:
            - sub: User ID (UUID or test ID)
            - email: User email (in test mode: "test@example.com")
            - role: User role
            - aud: Audience
            - exp: Expiration timestamp
            - iat: Issued at timestamp

    Raises:
        HTTPException 401: If token is missing, invalid, or expired
   """
    # Check for test mode header (only in non-production environments)
    environment = os.getenv("ENVIRONMENT", "development").lower()
    if environment != "production" and x_test_user_id:
        # Test mode: return mock payload with test user ID
        return {
            "sub": x_test_user_id,
            "email": "test@example.com",
            "role": "authenticated",
            "aud": "authenticated",
        }

    # Production/normal mode: require JWT token
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authenticated",
        )

    token = credentials.credentials
    payload = verify_jwt_token(token)

    # Ensure user ID exists in payload
    if "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing user ID",
        )

    return payload


async def get_current_user_id_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
) -> Optional[int]:
    """
    Optional JWT authentication - returns user ID if token present, None otherwise.

    Use this for endpoints that work both with and without authentication.

    Usage in endpoints:
    ```python
    @router.get("/events/{event_id}")
    async def get_event(
        event_id: int,
        current_user_id: Optional[int] = Depends(get_current_user_id_optional),
        db: Session = Depends(get_db)
    ):
        if current_user_id:
            # User is authenticated
        else:
            # Anonymous access
    ```

    Returns:
        Optional[int]: User ID if authenticated, None if no token provided

    Raises:
        HTTPException 401: If token is present but invalid
    """
    from dependencies import get_db as _get_db
    from models import User

    if credentials is None:
        return None

    try:
        # Validate token
        token = credentials.credentials
        payload = verify_jwt_token(token)
        user_uuid = payload["sub"]

        # Get user from database
        db_gen = _get_db()
        db = next(db_gen)
        try:
            user = db.query(User).filter(User.auth_id == user_uuid).first()
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found in database",
                )
            return user.id
        finally:
            db.close()

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )


async def get_current_user_id(
    current_user: dict = Depends(get_current_user)
) -> int:
    """
    Extract integer user ID from JWT payload and validate against database.

    Supabase returns UUID as 'sub', but your app uses integer IDs.
    This dependency queries the database to find the user by auth_id.

    In test mode (X-Test-User-Id header), sub contains the integer user ID directly.

    Usage in endpoints:
    ```python
    from auth import get_current_user_id

    @router.put("/events/{event_id}")
    async def update_event(
        event_id: int,
        event_data: EventCreate,
        current_user_id: int = Depends(get_current_user_id),
        db: Session = Depends(get_db)
    ):
        # ... use current_user_id as before
    ```

    Args:
        current_user: JWT payload from get_current_user dependency

    Returns:
        int: User ID from your database

    Raises:
        HTTPException 401: If user not found or invalid token
    """
    from dependencies import get_db as _get_db
    from models import User
    from sqlalchemy.orm import Session

    try:
        user_sub = current_user["sub"]

        # Check if this is a test mode request (sub is a numeric string)
        try:
            # If sub can be converted to int, it's a test mode user ID
            return int(user_sub)
        except ValueError:
            # Not a numeric ID, so it's a UUID - query database
            pass

        # Get db session manually (function doesn't use dependency injection for db)
        db_gen = _get_db()
        db = next(db_gen)

        try:
            # Query user by auth_id (contains Supabase UUID)
            user = db.query(User).filter(User.auth_id == user_sub).first()

            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found in database",
                )

            return user.id
        finally:
            db.close()

    except HTTPException:
        raise
    except (ValueError, KeyError) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid user ID in token: {str(e)}",
        )
