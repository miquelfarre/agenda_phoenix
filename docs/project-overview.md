# Agenda Phoenix - Project Overview

## What is Agenda Phoenix?

Agenda Phoenix is a calendar and event management system designed with a clear separation between:
- **Backend:** FastAPI-based REST API (source of truth)
- **CLI:** Interactive command-line interface (design & testing tool)

---

## Quick Start

### 1. Start the Backend
```bash
cd backend
docker-compose up -d
uvicorn main:app --reload --port 8001
```

### 2. Run the CLI
```bash
cd cli
python menu.py
```

---

## Project Structure

```
agenda_phoenix/
├── backend/
│   ├── main.py              # FastAPI application & endpoints
│   ├── models.py            # SQLAlchemy models
│   ├── database.py          # Database configuration
│   ├── init_db.py          # Database initialization & sample data
│   └── docker-compose.yml   # PostgreSQL container
│
├── cli/
│   ├── menu.py              # Interactive CLI application (refactored)
│   ├── utils.py             # Utility functions (NEW - refactored)
│   ├── config.py            # CLI configuration
│   ├── requirements.txt     # Python dependencies
│   └── start.sh            # Startup script
│
└── docs/
    ├── API_ENDPOINTS.md     # Complete endpoint inventory (79 endpoints)
    ├── CLI_ANALYSIS.md      # CLI code analysis & cleanup plan
    ├── CLI_FILES.md         # CLI structure documentation (NEW)
    ├── DEVELOPMENT_RULES.md # Development workflow & rules
    ├── PROJECT_OVERVIEW.md  # This file
    └── REFACTORING_SUMMARY.md # Refactoring details (NEW)
```

---

## Key Documents (READ THESE!)

### 1. [API_ENDPOINTS.md](backend/API_ENDPOINTS.md)
**Purpose:** Complete inventory of all 78 backend endpoints

**When to use:**
- Before implementing a new feature (check if endpoint exists)
- When writing CLI code (know what's available)
- When planning new endpoints

**Contents:**
- All endpoints grouped by resource
- Request/response schemas
- Query parameters
- Special behaviors

### 2. [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)
**Purpose:** How to develop features correctly

**When to use:**
- Before adding any new feature
- When reviewing code
- When unsure where code should go

**Key principles:**
- CLI = Design tool (UI only)
- Backend = Logic (source of truth)
- Clear decision tree for code placement

### 3. [CLI_ANALYSIS.md](CLI_ANALYSIS.md)
**Purpose:** Current CLI problems and cleanup plan

**When to use:**
- Before modifying CLI code
- When planning CLI refactoring
- To understand what NOT to do

**Key insights:**
- What's good in current CLI
- What needs to be removed
- Specific refactoring tasks

---

## Development Workflow

### Adding a New Feature

```
1. Design in CLI (mockup)
   └─→ Create menu option
   └─→ Design user flow
   └─→ Define needed API data

2. Define API Contract
   └─→ Document in API_ENDPOINTS.md
   └─→ Define request/response
   └─→ Define errors

3. Implement Backend
   └─→ Create endpoint
   └─→ Add validation
   └─→ Test with curl

4. Connect CLI
   └─→ Replace mock with real API call
   └─→ Display results
   └─→ Handle errors

5. Update Docs
   └─→ Finalize API_ENDPOINTS.md entry
   └─→ Add examples if needed
```

---

## Core Principles

### 1. Separation of Concerns

```
CLI (menu.py)              Backend (main.py)
├─ Menus & navigation      ├─ Business logic
├─ User input             ├─ Data validation
├─ Display data           ├─ Calculations
└─ API calls (simple)     └─ Database operations
```

### 2. Single Source of Truth

**Backend is the source of truth.**
- All data lives in the backend database
- All validation happens in backend
- All business rules enforced by backend
- CLI is just a client

### 3. API-First Design

**Everything goes through the API.**
- CLI never directly accesses database
- CLI never implements business logic
- CLI can be replaced with web/mobile app

---

## Common Tasks

### View All Endpoints
```bash
cat backend/API_ENDPOINTS.md
# or
curl http://localhost:8001/ | jq
```

### Test an Endpoint
```bash
# Example: Get all users
curl http://localhost:8001/users | jq

# Example: Get user events
curl "http://localhost:8001/users/1/events?from_date=2024-01-01" | jq
```

### Check Database
```bash
docker exec -it agenda_phoenix_db psql -U agenda_user -d agenda_phoenix
```

---

## Current Status

### ✅ Completed
- Backend with 78 endpoints
- Full CRUD operations for all entities
- Event conflict detection
- User dashboard with statistics
- Recurring events support
- Interactive CLI with dual modes (User/Backoffice)

### 📋 Documented
- Complete API endpoint inventory
- Development rules and workflow
- CLI analysis and cleanup plan
- Project structure

### 🔄 Needs Cleanup
- CLI has some business logic (should be removed)
- Some bulk operations need dedicated endpoints
- Some functions too long/complex

### ⏭️ Future Enhancements
- Authentication & authorization
- WebSocket notifications
- Email invitations
- Export/import functionality
- Search improvements
- Performance optimization

---

## Problem Resolution

### "I need to add a feature but don't know where"

1. Check [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) - Decision Tree section
2. Ask: "Does this involve data/logic?" → Backend
3. Ask: "Is this just UI?" → CLI

### "There's too much logic in the CLI"

1. Read [CLI_ANALYSIS.md](CLI_ANALYSIS.md)
2. Follow the refactoring tasks
3. Move logic to backend
4. Simplify CLI to just API calls

### "I don't know what endpoints exist"

1. Check [API_ENDPOINTS.md](backend/API_ENDPOINTS.md)
2. Use the root endpoint: `curl http://localhost:8001/`
3. Try the interactive docs: `http://localhost:8001/docs`

### "The code is messy and hard to understand"

**That's what we're fixing!**

The problem was:
- No inventory of endpoints
- Code added without clear rules
- CLI became too complex

The solution:
- [API_ENDPOINTS.md](backend/API_ENDPOINTS.md) - Know what exists
- [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) - Clear rules
- [CLI_ANALYSIS.md](CLI_ANALYSIS.md) - Cleanup plan

---

## Code Review Checklist

Before committing code:

### For CLI Changes:
- [ ] Does it make max 1-2 API calls?
- [ ] No calculations or business logic?
- [ ] No loops creating multiple API calls?
- [ ] Just displaying data from API?

### For Backend Changes:
- [ ] Endpoint documented in API_ENDPOINTS.md?
- [ ] All inputs validated?
- [ ] Proper error handling?
- [ ] Returns structured data?

---

## Anti-Patterns to Avoid

### ❌ DON'T: Add logic to CLI
```python
# BAD: Calculating in CLI
for event in events:
    duration += (event.end - event.start).seconds
```

### ✅ DO: Add endpoint to backend
```python
# GOOD: Let backend calculate
stats = requests.get("/users/1/stats").json()
duration = stats['total_duration']
```

### ❌ DON'T: Loop API calls in CLI
```python
# BAD: Creating multiple calls
for user in users:
    requests.post("/interactions", json={...})
```

### ✅ DO: Create bulk endpoint
```python
# GOOD: Single bulk call
requests.post("/events/1/invite-users", json={"user_ids": [...]})
```

---

## Getting Help

### Questions to Ask:

1. **"Where should this code go?"**
   → Read [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) - Decision Tree

2. **"Does this endpoint exist?"**
   → Check [API_ENDPOINTS.md](backend/API_ENDPOINTS.md)

3. **"Why is the CLI so complex?"**
   → Read [CLI_ANALYSIS.md](CLI_ANALYSIS.md)

4. **"How do I add a new feature?"**
   → Follow the Development Workflow in this document

---

## Success Metrics

You're doing it right when:
- ✅ CLI functions are short and simple
- ✅ Backend has all the logic
- ✅ Easy to find endpoints in API_ENDPOINTS.md
- ✅ New features follow the workflow
- ✅ Code is self-explanatory

You're doing it wrong when:
- ❌ CLI has calculations or loops
- ❌ Unsure what endpoints exist
- ❌ Adding code without checking docs
- ❌ Backend and CLI have duplicate logic

---

## Next Steps

### Immediate (High Priority):
1. Read [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)
2. Review [API_ENDPOINTS.md](backend/API_ENDPOINTS.md)
3. Follow the workflow for new features

### Short Term:
1. Refactor CLI following [CLI_ANALYSIS.md](CLI_ANALYSIS.md)
2. Add missing bulk endpoints
3. Update API docs as needed

### Long Term:
1. Add authentication
2. Create web frontend
3. Add real-time features
4. Improve performance

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                        Users                            │
└────────────┬────────────────────────────┬───────────────┘
             │                            │
             ▼                            ▼
┌────────────────────────┐   ┌───────────────────────────┐
│    CLI (menu.py)       │   │   Future: Web/Mobile      │
│  - Interactive menus   │   │   - React/Vue/Flutter     │
│  - API client          │   │   - Same API              │
└───────────┬────────────┘   └──────────┬────────────────┘
            │                           │
            │        HTTP Requests      │
            └───────────┬───────────────┘
                        ▼
            ┌───────────────────────┐
            │   FastAPI Backend     │
            │   (main.py)           │
            │  - 78 endpoints       │
            │  - Business logic     │
            │  - Validation         │
            └──────────┬────────────┘
                       │
                       ▼
            ┌───────────────────────┐
            │   PostgreSQL DB       │
            │  - Events             │
            │  - Users              │
            │  - Calendars          │
            │  - Interactions       │
            └───────────────────────┘
```

---

## Final Notes

**This project is being reorganized to be clean, maintainable, and scalable.**

The three key documents are:
1. **API_ENDPOINTS.md** - What exists
2. **DEVELOPMENT_RULES.md** - How to work
3. **CLI_ANALYSIS.md** - What to fix

Follow these, and the codebase will stay clean and organized.

**Remember: When in doubt, put it in the backend!**
