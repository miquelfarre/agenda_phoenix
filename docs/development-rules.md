# Development Rules & Workflow - Agenda Phoenix

## Core Principles

### 1. Separation of Concerns

```
┌─────────────────────────────────────────┐
│             CLI (menu.py)               │
│  - UI/UX flows                          │
│  - Input collection                     │
│  - Display API responses                │
│  - Design & testing tool                │
└──────────────┬──────────────────────────┘
               │ HTTP Requests
               │ (simple API calls)
               ▼
┌─────────────────────────────────────────┐
│          Backend (main.py)              │
│  - Business logic                       │
│  - Data validation                      │
│  - Calculations & aggregations          │
│  - Database operations                  │
│  - Source of truth                      │
└─────────────────────────────────────────┘
```

### 2. CLI Philosophy

**CLI = Interactive API Client**

The CLI is a **consumer** of the API, not a **part** of the API.

Think of it as:
- A Postman alternative with a nice UI
- A tool to design and test user flows
- A demonstration of how to use the API

**NOT:**
- A place to implement features
- A place to store business rules
- A workaround for missing API endpoints

---

## Development Workflow

### Step 1: Design in CLI (Mockup Phase)

**When adding a new feature:**

1. Create the menu option in CLI
2. Create mock functions with `console.print("[yellow]TODO: This will do X[/yellow]")`
3. Design the user flow with questionary
4. Define what data you need from the API
5. Define what data you'll send to the API

**Example:**
```python
def invitar_usuarios_a_evento():
    """Invita múltiples usuarios a un evento"""
    clear_screen()
    show_header()

    console.print("[yellow]TODO: Feature to invite users to event[/yellow]")
    console.print("[dim]Will need API endpoint: POST /events/{event_id}/invite-users[/dim]")
    console.print("[dim]Body: {user_ids: [1, 2, 3]}[/dim]")
    pause()
```

### Step 2: Define API Contract

**Before implementing in backend:**

1. Document the endpoint in `backend/API_ENDPOINTS.md`
2. Define request/response schemas
3. Define error cases
4. Review if endpoint already exists or can be enhanced

**Example entry in API_ENDPOINTS.md:**
```markdown
### POST /events/{event_id}/invite-users
- **Description:** Invite multiple users to an event
- **Params:** event_id (int)
- **Body:** {"user_ids": [int, ...]}
- **Response:** {"invited_count": int, "failed_count": int}
- **Errors:** 404 if event not found, 400 if user_ids invalid
```

### Step 3: Implement in Backend

**When implementing the endpoint:**

1. Create Pydantic schema if needed
2. Implement endpoint function
3. Add proper error handling
4. Add business logic validation
5. Test with curl or Postman

**Example:**
```python
@app.post("/events/{event_id}/invite-users")
async def invite_users_to_event(
    event_id: int,
    user_ids: List[int],
    invited_by: int,
    db: Session = Depends(get_db)
):
    """Invite multiple users to an event"""
    # Verify event exists
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    invited_count = 0
    failed_count = 0

    for user_id in user_ids:
        # Business logic here
        ...

    return {
        "invited_count": invited_count,
        "failed_count": failed_count
    }
```

### Step 4: Connect CLI to Backend

**Replace the mock with actual API call:**

```python
def invitar_usuarios_a_evento():
    """Invita múltiples usuarios a un evento"""
    clear_screen()
    show_header()

    # Collect input
    event_id = questionary.text("ID del evento:").ask()
    # ... collect user_ids

    # Single API call
    data = {
        "user_ids": selected_user_ids,
        "invited_by": usuario_actual
    }

    response = requests.post(
        f"{API_BASE_URL}/events/{event_id}/invite-users",
        json=data
    )

    result = handle_api_error(response)
    if result:
        console.print(f"[green]✅ {result['invited_count']} usuarios invitados[/green]")
        if result['failed_count'] > 0:
            console.print(f"[yellow]⚠️  {result['failed_count']} fallos[/yellow]")

    pause()
```

### Step 5: Update Documentation

**After implementation:**

1. Update `backend/API_ENDPOINTS.md` with final details
2. Add example usage if complex
3. Update CLI feature list if needed

---

## Rules by Category

### ✅ CLI Rules (ALLOWED)

#### 1. Input Collection
```python
# ✅ GOOD: Simple input validation
name = questionary.text(
    "Nombre:",
    validate=lambda t: len(t) > 0 or "No puede estar vacío"
).ask()

# ✅ GOOD: Format validation
phone = questionary.text(
    "Teléfono (+34XXXXXXXXX):",
    validate=lambda t: t.startswith("+") or "Debe empezar con +"
).ask()
```

#### 2. Single API Calls
```python
# ✅ GOOD: Single API call
response = requests.get(f"{API_BASE_URL}/users/{user_id}/events")
events = handle_api_error(response)

# ✅ GOOD: Single API call with params
params = {"from_date": from_date, "to_date": to_date}
response = requests.get(
    f"{API_BASE_URL}/users/{user_id}/events",
    params=params
)
```

#### 3. Display Logic
```python
# ✅ GOOD: Display API data
table = Table(title="Eventos")
for event in events:
    table.add_row(event['name'], event['date'])
console.print(table)
```

### ❌ CLI Rules (NOT ALLOWED)

#### 1. Business Logic
```python
# ❌ BAD: Calculating in CLI
total_duration = 0
for event in events:
    if event.get('end_date'):
        duration = (event['end_date'] - event['start_date']).seconds
        total_duration += duration

# ✅ GOOD: Let API do it
response = requests.get(f"{API_BASE_URL}/users/{user_id}/stats")
stats = handle_api_error(response)
total_duration = stats['total_duration']
```

#### 2. Loops Creating Multiple API Calls
```python
# ❌ BAD: Loop creating subscriptions
for event in events:
    requests.post(f"{API_BASE_URL}/interactions", json={
        "event_id": event['id'],
        "user_id": user_id,
        "type": "subscribed"
    })

# ✅ GOOD: Single bulk endpoint
requests.post(
    f"{API_BASE_URL}/users/{user_id}/subscribe/{target_user_id}"
)
```

#### 3. Data Transformation
```python
# ❌ BAD: Transforming data in CLI
events_by_month = {}
for event in events:
    month = event['start_date'][:7]  # YYYY-MM
    if month not in events_by_month:
        events_by_month[month] = []
    events_by_month[month].append(event)

# ✅ GOOD: API provides grouped data
response = requests.get(
    f"{API_BASE_URL}/users/{user_id}/events/grouped-by-month"
)
events_by_month = handle_api_error(response)
```

---

## Backend Rules

### ✅ Backend Rules (REQUIRED)

#### 1. Complete Validation
```python
# ✅ Validate everything
if not event:
    raise HTTPException(status_code=404, detail="Event not found")

if event.owner_id != user_id:
    raise HTTPException(status_code=403, detail="Not authorized")
```

#### 2. Return Structured Data
```python
# ✅ Return what CLI needs
return {
    "total_events": len(events),
    "upcoming_events": upcoming,
    "past_events": past,
    "summary": {
        "total_duration": total_duration,
        "most_common_type": most_common_type
    }
}
```

#### 3. Bulk Operations
```python
# ✅ Provide bulk endpoints when needed
@app.post("/events/{event_id}/invite-users")
async def invite_users_bulk(event_id: int, user_ids: List[int], ...):
    # Handle multiple operations efficiently
    ...
```

### ❌ Backend Rules (NOT ALLOWED)

#### 1. Trusting Client Input
```python
# ❌ BAD: No validation
@app.post("/events")
async def create_event(event: EventCreate, db: Session):
    db_event = Event(**event.dict())
    db.add(db_event)
    db.commit()

# ✅ GOOD: Validate everything
@app.post("/events")
async def create_event(event: EventCreate, db: Session):
    # Verify owner exists
    owner = db.query(User).filter(User.id == event.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    # Verify no conflicts
    conflicts = check_conflicts(...)
    if conflicts:
        raise HTTPException(status_code=409, detail="Event conflicts")

    # Then create
    ...
```

#### 2. Returning Raw DB Objects
```python
# ❌ BAD: Returning inconsistent data
return db.query(Event).all()  # Might include internal fields

# ✅ GOOD: Use Pydantic schemas
return [EventResponse.from_orm(event) for event in events]
```

---

## Decision Tree: Where Does This Code Go?

```
Does this involve database operations?
├─ YES → Backend
└─ NO
    └─ Does this involve calculations or aggregations?
        ├─ YES → Backend
        └─ NO
            └─ Does this involve multiple API calls?
                ├─ YES → Create backend endpoint
                └─ NO
                    └─ Is this just displaying data?
                        ├─ YES → CLI
                        └─ NO → Probably Backend
```

---

## Common Scenarios

### Scenario 1: Need to filter events

**❌ Wrong approach:**
```python
# CLI
all_events = requests.get(f"{API_BASE_URL}/events").json()
filtered = [e for e in all_events if e['date'] > today]
```

**✅ Right approach:**
```python
# CLI
params = {"from_date": today.isoformat()}
events = requests.get(f"{API_BASE_URL}/events", params=params).json()
```

### Scenario 2: Need to count something

**❌ Wrong approach:**
```python
# CLI
events = requests.get(f"{API_BASE_URL}/users/{user_id}/events").json()
count = len([e for e in events if e['type'] == 'birthday'])
```

**✅ Right approach:**
```python
# Backend: Add to dashboard endpoint
stats = requests.get(f"{API_BASE_URL}/users/{user_id}/dashboard").json()
birthday_count = stats['birthday_events_count']
```

### Scenario 3: Need to create multiple related objects

**❌ Wrong approach:**
```python
# CLI: Loop creating
for user_id in user_ids:
    requests.post(f"{API_BASE_URL}/interactions", json={...})
```

**✅ Right approach:**
```python
# Backend: Bulk endpoint
@app.post("/events/{event_id}/invite-users")

# CLI: Single call
requests.post(f"{API_BASE_URL}/events/{event_id}/invite-users",
             json={"user_ids": user_ids})
```

---

## Code Review Checklist

Before submitting code, ask:

### CLI Code Review:
- [ ] Does each function make max 1-2 API calls?
- [ ] Is there any calculation logic? (should be in backend)
- [ ] Is there any loop creating multiple API calls? (needs bulk endpoint)
- [ ] Are we transforming API data beyond display formatting?
- [ ] Could this be simplified by adding/modifying a backend endpoint?

### Backend Code Review:
- [ ] Are all inputs validated?
- [ ] Are all errors handled with proper HTTP codes?
- [ ] Is this endpoint documented in API_ENDPOINTS.md?
- [ ] Does it return structured data (not raw DB objects)?
- [ ] Is business logic separated from routing logic?

---

## Refactoring Priorities

When you see these patterns, refactor immediately:

### Priority 1 (Critical):
1. Loops in CLI creating multiple API calls
2. Business calculations in CLI
3. Data validation only in CLI

### Priority 2 (Important):
1. Duplicate logic between CLI and backend
2. Complex multi-step operations in CLI
3. Missing error handling

### Priority 3 (Nice to have):
1. Long functions (>50 lines)
2. Unclear variable names
3. Missing comments on complex logic

---

## Summary

### The Golden Rule:

**If you're unsure where code should go, put it in the backend.**

It's easier to call a backend endpoint from CLI than to move logic from CLI to backend later.

### Three Questions:

1. **What does the user want to do?** → Design in CLI
2. **What data/logic is needed?** → Implement in Backend
3. **How do we connect them?** → Simple API call in CLI

### Success Metrics:

- ✅ New developer can add a feature without touching backend (if endpoint exists)
- ✅ CLI can be rewritten in another language without losing functionality
- ✅ Backend can be tested without CLI
- ✅ API endpoints are self-documenting and discoverable
