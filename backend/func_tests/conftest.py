"""
Fixtures para tests funcionales basados en JSON
"""

import os

import pytest


def pytest_addoption(parser):
    """Añade opciones personalizadas a pytest"""
    parser.addoption("--update-snapshots", action="store_true", default=False, help="Update snapshots instead of comparing")
    parser.addoption("--update-expected", action="store_true", default=False, help="Update expected.body in test files with actual normalized responses")


from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Set test database URL BEFORE importing database module
os.environ["DATABASE_URL"] = "sqlite:///./func_test.db"

from database import Base, get_db
from main import app

# Base de datos de test (SQLite)
TEST_DATABASE_URL = "sqlite:///./func_test.db"


@pytest.fixture(scope="function")
def test_engine():
    """Crear engine de BD para tests"""
    engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


@pytest.fixture(scope="function")
def test_db(test_engine):
    """Crear sesión de BD limpia para cada test"""
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.rollback()
        db.close()


@pytest.fixture
def client(test_db, monkeypatch, request):
    """Cliente HTTP de test con TestClient de FastAPI"""

    # Override dependency
    def override_get_db():
        try:
            yield test_db
        finally:
            pass

    # Mock JWT authentication - returns user_id from test request context
    # Tests can specify auth_user_id in the request to set the authenticated user
    def mock_get_current_user_id():
        # Get auth_user_id from test context if available
        if hasattr(request, '_auth_user_id'):
            return request._auth_user_id
        # Default to user 1 if not specified
        return 1

    # Mock optional JWT authentication - same as above
    def mock_get_current_user_id_optional():
        if hasattr(request, '_auth_user_id'):
            return request._auth_user_id
        return None

    # Mock the init_database function to do nothing during tests
    def mock_init_database():
        pass

    monkeypatch.setattr("main.init_database", mock_init_database)

    # Import auth dependencies
    from auth import get_current_user_id, get_current_user_id_optional

    # Override dependencies
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user_id] = mock_get_current_user_id
    app.dependency_overrides[get_current_user_id_optional] = mock_get_current_user_id_optional

    with TestClient(app, raise_server_exceptions=True) as test_client:
        yield test_client

    app.dependency_overrides.clear()
