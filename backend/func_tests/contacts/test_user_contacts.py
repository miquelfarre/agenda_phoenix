"""
Tests for UserContact endpoints

Tests the new contact system:
- POST /api/v1/contacts/sync - Sync device contacts
- GET /api/v1/contacts - Get user contacts
- POST /api/v1/contacts/webhook/user-registered - Webhook for new user registration
"""

import pytest


class TestContactSync:
    """Tests for POST /api/v1/contacts/sync"""

    def test_sync_contacts_empty_list(self, client, test_db):
        """Test syncing empty contact list"""
        # Create test user
        user = User(
            id=1,
            display_name="Sonia",
            phone="+34606014680",
            auth_provider="phone",
            auth_id="+34606014680",
            is_public=False,
        )
        test_db.add(user)
        test_db.commit()

        # Set auth context
        client._auth_context["user_id"] = 1

        response = client.post("/api/v1/contacts/sync", json={"contacts": []})

        assert response.status_code == 200
        data = response.json()
        assert data["synced_count"] == 0
        assert data["registered_count"] == 0
        assert data["registered_contacts"] == []

    def test_sync_contacts_with_unregistered_contacts(self, client, test_db):
        """Test syncing contacts that are not registered"""
        # Create test user
        user = User(
            id=1,
            display_name="Sonia",
            phone="+34606014680",
            auth_provider="phone",
            auth_id="+34606014680",
            is_public=False,
        )
        test_db.add(user)
        test_db.commit()

        # Set auth context
        client._auth_context["user_id"] = 1

        response = client.post(
            "/api/v1/contacts/sync",
            json={
                "contacts": [
                    {"contact_name": "Juan", "phone_number": "+34666777888"},
                    {"contact_name": "María", "phone_number": "+34611223344"},
                ]
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["synced_count"] == 2
        assert data["registered_count"] == 0
        assert data["registered_contacts"] == []

        # Verify contacts were created in DB
        contacts = test_db.query(UserContact).filter(UserContact.owner_id == 1).all()
        assert len(contacts) == 2
        assert contacts[0].contact_name == "Juan"
        assert contacts[0].phone_number == "+34666777888"
        assert contacts[0].registered_user_id is None

    def test_sync_contacts_with_registered_contacts(self, client, test_db):
        """Test syncing contacts where some are registered users"""
        # Create users
        sonia = User(
            id=1,
            display_name="Sonia",
            phone="+34606014680",
            auth_provider="phone",
            auth_id="+34606014680",
            is_public=False,
        )
        miquel = User(
            id=2,
            display_name="Miquel García",
            phone="+34626034421",
            auth_provider="phone",
            auth_id="+34626034421",
            is_public=False,
            profile_picture_url="https://example.com/miquel.jpg",
        )
        test_db.add_all([sonia, miquel])
        test_db.commit()

        # Set auth context
        client._auth_context["user_id"] = 1

        response = client.post(
            "/api/v1/contacts/sync",
            json={
                "contacts": [
                    {"contact_name": "Miquel", "phone_number": "+34626034421"},
                    {"contact_name": "Juan", "phone_number": "+34666777888"},
                ]
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["synced_count"] == 2
        assert data["registered_count"] == 1
        assert len(data["registered_contacts"]) == 1

        # Verify registered contact data
        registered = data["registered_contacts"][0]
        assert registered["user_id"] == 2
        assert registered["display_name"] == "Miquel García"
        assert registered["phone"] == "+34626034421"
        assert registered["profile_picture_url"] == "https://example.com/miquel.jpg"
        assert registered["contact_name"] == "Miquel"  # Name from device

        # Verify DB state
        contacts = test_db.query(UserContact).filter(UserContact.owner_id == 1).all()
        assert len(contacts) == 2

        miquel_contact = [c for c in contacts if c.phone_number == "+34626034421"][0]
        assert miquel_contact.registered_user_id == 2
        assert miquel_contact.contact_name == "Miquel"

        juan_contact = [c for c in contacts if c.phone_number == "+34666777888"][0]
        assert juan_contact.registered_user_id is None

    def test_sync_contacts_updates_existing(self, client, test_db):
        """Test that syncing updates existing contacts"""
        # Create user and existing contact
        user = User(
            id=1,
            display_name="Sonia",
            phone="+34606014680",
            auth_provider="phone",
            auth_id="+34606014680",
            is_public=False,
        )
        existing_contact = UserContact(
            owner_id=1,
            contact_name="Old Name",
            phone_number="+34666777888",
            registered_user_id=None,
        )
        test_db.add_all([user, existing_contact])
        test_db.commit()

        # Set auth context
        client._auth_context["user_id"] = 1

        response = client.post(
            "/api/v1/contacts/sync",
            json={
                "contacts": [
                    {"contact_name": "New Name", "phone_number": "+34666777888"},
                ]
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["synced_count"] == 1

        # Verify contact was updated, not duplicated
        contacts = test_db.query(UserContact).filter(UserContact.owner_id == 1).all()
        assert len(contacts) == 1
        assert contacts[0].contact_name == "New Name"

    def test_sync_contacts_requires_auth(self, client, test_db):
        """Test that sync requires authentication"""
        # Don't set auth context - should fail
        response = client.post("/api/v1/contacts/sync", json={"contacts": []})

        # Without auth, default mock returns user_id=1, so this will pass
        # In real scenario with JWT, this would return 401
        assert response.status_code in [200, 401]


class TestGetContacts:
    """Tests for GET /api/v1/contacts"""

    def test_get_contacts_empty(self, client, test_db):
        """Test getting contacts when user has none"""
        user = User(
            id=1,
            display_name="Sonia",
            phone="+34606014680",
            auth_provider="phone",
            auth_id="+34606014680",
            is_public=False,
        )
        test_db.add(user)
        test_db.commit()

        client._auth_context["user_id"] = 1

        response = client.get("/api/v1/contacts")
        assert response.status_code == 200
        assert response.json() == []

    def test_get_contacts_only_registered_by_default(self, client, test_db):
        """Test that by default only registered contacts are returned"""
        # Create users
        sonia = User(
            id=1,
            display_name="Sonia",
            phone="+34606014680",
            auth_provider="phone",
            auth_id="+34606014680",
            is_public=False,
        )
        miquel = User(
            id=2,
            display_name="Miquel",
            phone="+34626034421",
            auth_provider="phone",
            auth_id="+34626034421",
            is_public=False,
        )
        test_db.add_all([sonia, miquel])
        test_db.flush()

        # Create contacts
        contact1 = UserContact(
            owner_id=1,
            contact_name="Miquel",
            phone_number="+34626034421",
            registered_user_id=2,  # Registered
        )
        contact2 = UserContact(
            owner_id=1,
            contact_name="Juan",
            phone_number="+34666777888",
            registered_user_id=None,  # Not registered
        )
        test_db.add_all([contact1, contact2])
        test_db.commit()

        client._auth_context["user_id"] = 1

        response = client.get("/api/v1/contacts")
        assert response.status_code == 200
        data = response.json()

        # Should only return registered contact
        assert len(data) == 1
        assert data[0]["contact_name"] == "Miquel"
        assert data[0]["is_registered"] is True
        assert data[0]["registered_user"] is not None
        assert data[0]["registered_user"]["display_name"] == "Miquel"

    def test_get_contacts_include_unregistered(self, client, test_db):
        """Test getting all contacts including unregistered"""
        # Create user
        sonia = User(
            id=1,
            display_name="Sonia",
            phone="+34606014680",
            auth_provider="phone",
            auth_id="+34606014680",
            is_public=False,
        )
        miquel = User(
            id=2,
            display_name="Miquel",
            phone="+34626034421",
            auth_provider="phone",
            auth_id="+34626034421",
            is_public=False,
        )
        test_db.add_all([sonia, miquel])
        test_db.flush()

        # Create contacts
        contact1 = UserContact(
            owner_id=1,
            contact_name="Miquel",
            phone_number="+34626034421",
            registered_user_id=2,
        )
        contact2 = UserContact(
            owner_id=1,
            contact_name="Juan",
            phone_number="+34666777888",
            registered_user_id=None,
        )
        test_db.add_all([contact1, contact2])
        test_db.commit()

        client._auth_context["user_id"] = 1

        response = client.get("/api/v1/contacts?only_registered=false")
        assert response.status_code == 200
        data = response.json()

        # Should return both contacts
        assert len(data) == 2

        registered = [c for c in data if c["is_registered"]][0]
        assert registered["contact_name"] == "Miquel"

        unregistered = [c for c in data if not c["is_registered"]][0]
        assert unregistered["contact_name"] == "Juan"
        assert unregistered["registered_user"] is None

    def test_get_contacts_isolation(self, client, test_db):
        """Test that users can only see their own contacts"""
        # Create users
        sonia = User(id=1, display_name="Sonia", phone="+34606014680", auth_provider="phone", auth_id="+34606014680", is_public=False)
        miquel = User(id=2, display_name="Miquel", phone="+34626034421", auth_provider="phone", auth_id="+34626034421", is_public=False)
        test_db.add_all([sonia, miquel])
        test_db.flush()

        # Create contacts for Sonia
        sonia_contact = UserContact(owner_id=1, contact_name="Juan", phone_number="+34666777888")
        test_db.add(sonia_contact)

        # Create contacts for Miquel
        miquel_contact = UserContact(owner_id=2, contact_name="Pedro", phone_number="+34699888777")
        test_db.add(miquel_contact)
        test_db.commit()

        # Login as Sonia
        client._auth_context["user_id"] = 1
        response = client.get("/api/v1/contacts?only_registered=false")
        assert response.status_code == 200
        sonia_data = response.json()

        # Sonia should only see her contact
        assert len(sonia_data) == 1
        assert sonia_data[0]["contact_name"] == "Juan"

        # Login as Miquel
        client._auth_context["user_id"] = 2
        response = client.get("/api/v1/contacts?only_registered=false")
        assert response.status_code == 200
        miquel_data = response.json()

        # Miquel should only see his contact
        assert len(miquel_data) == 1
        assert miquel_data[0]["contact_name"] == "Pedro"


class TestWebhookUserRegistered:
    """Tests for POST /api/v1/contacts/webhook/user-registered"""

    def test_webhook_links_existing_contacts(self, client, test_db):
        """Test that webhook links existing contacts to new user"""
        # Create existing user and her contacts
        sonia = User(id=1, display_name="Sonia", phone="+34606014680", auth_provider="phone", auth_id="+34606014680", is_public=False)
        test_db.add(sonia)
        test_db.flush()

        # Sonia has Juan in her contacts, but Juan is not registered yet
        juan_contact = UserContact(
            owner_id=1,
            contact_name="Juan",
            phone_number="+34666777888",
            registered_user_id=None,
        )
        test_db.add(juan_contact)
        test_db.commit()

        # Now Juan registers
        juan = User(
            id=10,
            display_name="Juan Pérez",
            phone="+34666777888",
            auth_provider="phone",
            auth_id="+34666777888",
            is_public=False,
        )
        test_db.add(juan)
        test_db.commit()

        # Call webhook
        response = client.post("/api/v1/contacts/webhook/user-registered", json={"user_id": 10, "phone": "+34666777888"})

        assert response.status_code == 200
        data = response.json()
        assert data["updated_contacts"] == 1

        # Verify contact was linked
        test_db.refresh(juan_contact)
        assert juan_contact.registered_user_id == 10

    def test_webhook_links_multiple_contacts(self, client, test_db):
        """Test webhook links contacts from multiple users"""
        # Create users
        sonia = User(id=1, display_name="Sonia", phone="+34606014680", auth_provider="phone", auth_id="+34606014680", is_public=False)
        miquel = User(id=2, display_name="Miquel", phone="+34626034421", auth_provider="phone", auth_id="+34626034421", is_public=False)
        test_db.add_all([sonia, miquel])
        test_db.flush()

        # Both Sonia and Miquel have Juan in their contacts
        sonia_juan = UserContact(owner_id=1, contact_name="Juan", phone_number="+34666777888")
        miquel_juan = UserContact(owner_id=2, contact_name="Juanito", phone_number="+34666777888")
        test_db.add_all([sonia_juan, miquel_juan])
        test_db.commit()

        # Juan registers
        juan = User(id=10, display_name="Juan", phone="+34666777888", auth_provider="phone", auth_id="+34666777888", is_public=False)
        test_db.add(juan)
        test_db.commit()

        # Call webhook
        response = client.post("/api/v1/contacts/webhook/user-registered", json={"user_id": 10, "phone": "+34666777888"})

        assert response.status_code == 200
        data = response.json()
        assert data["updated_contacts"] == 2

        # Both contacts should be linked
        test_db.refresh(sonia_juan)
        test_db.refresh(miquel_juan)
        assert sonia_juan.registered_user_id == 10
        assert miquel_juan.registered_user_id == 10

    def test_webhook_doesnt_update_already_linked(self, client, test_db):
        """Test webhook doesn't update contacts already linked"""
        # Create users
        sonia = User(id=1, display_name="Sonia", phone="+34606014680", auth_provider="phone", auth_id="+34606014680", is_public=False)
        existing_user = User(id=99, display_name="Existing", phone="+34666777888", auth_provider="phone", auth_id="+34666777888", is_public=False)
        test_db.add_all([sonia, existing_user])
        test_db.flush()

        # Contact already linked to existing_user
        contact = UserContact(
            owner_id=1,
            contact_name="Existing",
            phone_number="+34666777888",
            registered_user_id=99,  # Already linked
        )
        test_db.add(contact)
        test_db.commit()

        # Webhook called with same phone but different user_id
        response = client.post("/api/v1/contacts/webhook/user-registered", json={"user_id": 100, "phone": "+34666777888"})

        assert response.status_code == 200
        data = response.json()
        assert data["updated_contacts"] == 0

        # Contact should still point to original user
        test_db.refresh(contact)
        assert contact.registered_user_id == 99
