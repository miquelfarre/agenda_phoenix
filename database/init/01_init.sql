--
-- PostgreSQL initial setup for Supabase
--

-- 1. Create schemas
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS realtime;

-- 2. Create roles
DO $$
BEGIN
  -- The supabase_admin role is the owner of all objects in the Supabase project
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin SUPERUSER;
  END IF;

  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin NOINHERIT CREATEROLE;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
    CREATE ROLE supabase_storage_admin NOINHERIT CREATEROLE;
  END IF;
END
$$;

-- 3. Grant privileges
GRANT USAGE ON SCHEMA public, auth, storage, extensions, realtime TO anon, authenticated, service_role;

GRANT ALL ON SCHEMA public, auth, storage, extensions, realtime TO postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA public, auth, storage, extensions, realtime GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public, auth, storage, extensions, realtime GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public, auth, storage, extensions, realtime GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;

-- 4. Set schema ownership
ALTER SCHEMA auth OWNER TO supabase_auth_admin;
ALTER SCHEMA storage OWNER TO supabase_storage_admin;

-- 5. Grant roles to postgres
GRANT supabase_admin TO postgres;
GRANT supabase_auth_admin TO postgres;
GRANT supabase_storage_admin TO postgres;
GRANT anon TO postgres;
GRANT authenticated TO postgres;
GRANT service_role TO postgres;

-- 6. Set search_path for roles
ALTER ROLE anon SET search_path = 'public';
ALTER ROLE authenticated SET search_path = 'public';
ALTER ROLE service_role SET search_path = 'public';

-- 7. Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA extensions;

-- ============================================================================
-- USER SUBSCRIPTION STATS TABLE (CDC Optimization)
-- ============================================================================
-- This table maintains pre-calculated statistics for user subscriptions
-- Updated automatically via triggers for maximum performance
-- Created: 2025-10-28
-- Ticket: CDC Architecture Unification

CREATE TABLE IF NOT EXISTS user_subscription_stats (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    new_events_count INTEGER DEFAULT 0,          -- Events created in last 7 days
    total_events_count INTEGER DEFAULT 0,        -- Total events created
    subscribers_count INTEGER DEFAULT 0,         -- Number of subscribers to user's events
    last_event_date TIMESTAMP,                   -- Last event creation date
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_stats_updated ON user_subscription_stats(updated_at);
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON user_subscription_stats(user_id);

-- Grant permissions for Realtime CDC
ALTER TABLE user_subscription_stats REPLICA IDENTITY FULL;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO authenticated;

-- ============================================================================
-- TRIGGER 1: Update stats when event is created
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_event_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_subscription_stats (
        user_id,
        total_events_count,
        new_events_count,
        last_event_date
    )
    VALUES (
        NEW.owner_id,
        1,
        CASE WHEN NEW.created_at > NOW() - INTERVAL '7 days' THEN 1 ELSE 0 END,
        NEW.created_at
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_events_count = user_subscription_stats.total_events_count + 1,
        new_events_count = CASE
            WHEN NEW.created_at > NOW() - INTERVAL '7 days'
            THEN user_subscription_stats.new_events_count + 1
            ELSE user_subscription_stats.new_events_count
        END,
        last_event_date = GREATEST(user_subscription_stats.last_event_date, NEW.created_at),
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_insert_stats_trigger
AFTER INSERT ON events
FOR EACH ROW
EXECUTE FUNCTION update_stats_on_event_insert();

-- ============================================================================
-- TRIGGER 2: Update stats when event is deleted
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_event_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE user_subscription_stats
    SET total_events_count = GREATEST(0, total_events_count - 1),
        new_events_count = CASE
            WHEN OLD.created_at > NOW() - INTERVAL '7 days'
            THEN GREATEST(0, new_events_count - 1)
            ELSE new_events_count
        END,
        updated_at = NOW()
    WHERE user_id = OLD.owner_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_delete_stats_trigger
AFTER DELETE ON events
FOR EACH ROW
EXECUTE FUNCTION update_stats_on_event_delete();

-- ============================================================================
-- TRIGGER 3: Update subscriber count on subscription
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_subscription()
RETURNS TRIGGER AS $$
DECLARE
    event_owner_id INTEGER;
BEGIN
    -- Get the owner of the event being subscribed to
    SELECT owner_id INTO event_owner_id
    FROM events
    WHERE id = NEW.event_id;

    IF event_owner_id IS NOT NULL AND NEW.interaction_type = 'subscribed' THEN
        INSERT INTO user_subscription_stats (user_id, subscribers_count)
        VALUES (event_owner_id, 1)
        ON CONFLICT (user_id) DO UPDATE SET
            subscribers_count = user_subscription_stats.subscribers_count + 1,
            updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_insert_stats_trigger
AFTER INSERT ON event_interactions
FOR EACH ROW
WHEN (NEW.interaction_type = 'subscribed')
EXECUTE FUNCTION update_stats_on_subscription();

-- ============================================================================
-- TRIGGER 4: Update subscriber count on unsubscription
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_unsubscription()
RETURNS TRIGGER AS $$
DECLARE
    event_owner_id INTEGER;
BEGIN
    -- Get the owner of the event being unsubscribed from
    SELECT owner_id INTO event_owner_id
    FROM events
    WHERE id = OLD.event_id;

    IF event_owner_id IS NOT NULL AND OLD.interaction_type = 'subscribed' THEN
        UPDATE user_subscription_stats
        SET subscribers_count = GREATEST(0, subscribers_count - 1),
            updated_at = NOW()
        WHERE user_id = event_owner_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_delete_stats_trigger
AFTER DELETE ON event_interactions
FOR EACH ROW
WHEN (OLD.interaction_type = 'subscribed')
EXECUTE FUNCTION update_stats_on_unsubscription();

-- ============================================================================
-- Initialize stats for existing users
-- ============================================================================
-- This runs once during initial setup to populate stats from existing data
INSERT INTO user_subscription_stats (user_id, total_events_count, new_events_count, subscribers_count, last_event_date)
SELECT
    u.id as user_id,
    COALESCE(e.total_events, 0) as total_events_count,
    COALESCE(e.new_events, 0) as new_events_count,
    COALESCE(s.subscribers, 0) as subscribers_count,
    e.last_event
FROM users u
LEFT JOIN (
    SELECT owner_id,
           COUNT(*) as total_events,
           COUNT(CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 1 END) as new_events,
           MAX(created_at) as last_event
    FROM events
    GROUP BY owner_id
) e ON u.id = e.owner_id
LEFT JOIN (
    SELECT e.owner_id, COUNT(DISTINCT ei.user_id) as subscribers
    FROM events e
    JOIN event_interactions ei ON e.id = ei.event_id
    WHERE ei.interaction_type = 'subscribed'
    GROUP BY e.owner_id
) s ON u.id = s.owner_id
ON CONFLICT (user_id) DO NOTHING;