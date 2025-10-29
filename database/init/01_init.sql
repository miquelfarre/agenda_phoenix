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
-- APPLICATION TABLES, TRIGGERS AND DATA
-- ============================================================================
-- All application-specific tables, triggers, views and data are now managed
-- by backend/init_db.py using SQLAlchemy models and raw SQL.
--
-- This separation ensures:
-- 1. Infrastructure setup (schemas, roles, extensions) happens first
-- 2. Application schema (tables, triggers) happens after with proper dependencies
-- 3. No duplication between SQL and Python code
-- 4. Easier maintenance and testing
-- ============================================================================