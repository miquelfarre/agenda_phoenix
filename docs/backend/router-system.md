# Backend Router System

**Version:** 2.0.0
**Last Updated:** 2025-10-18

---

## Overview

The backend uses FastAPI routers for modular endpoint organization. Each resource has its own router file.

---

## Structure

```
backend/
├── main.py (118 lines) ← Registers all routers
├── schemas.py (318 lines) ← Pydantic models
├── dependencies.py (17 lines) ← Shared dependencies
└── routers/
    ├── contacts.py (84 lines)
    ├── users.py (454 lines)
    ├── events.py (205 lines)
    ├── interactions.py (229 lines)
    ├── calendars.py (121 lines)
    ├── calendar_memberships.py (102 lines)
    ├── groups.py (79 lines)
    ├── group_memberships.py (83 lines)
    ├── recurring_configs.py (86 lines)
    ├── event_bans.py (88 lines)
    ├── user_blocks.py (83 lines)
    └── app_bans.py (82 lines)
```

**Total:** 1,831 lines (vs 1,829 in old monolithic main.py)

---

## How It Works

### 1. Router Definition

```python
# routers/contacts.py
from fastapi import APIRouter

router = APIRouter(
    prefix="/contacts",
    tags=["contacts"]
)

@router.get("")
async def get_contacts(db: Session = Depends(get_db)):
    return db.query(Contact).all()
```

### 2. Registration in main.py

```python
# main.py
from routers import contacts

app.include_router(contacts.router)
```

---

## Benefits

✅ **Modular**: Each resource in its own file
✅ **Maintainable**: Easy to find and modify endpoints
✅ **Scalable**: Add new routers without touching existing code
✅ **Testable**: Can test routers independently
✅ **Team-friendly**: Multiple developers can work in parallel

---

## Creating a New Router

```python
# 1. Create routers/my_resource.py
from fastapi import APIRouter, Depends
from dependencies import get_db

router = APIRouter(prefix="/my_resource", tags=["my_resource"])

@router.get("")
async def get_items(db: Session = Depends(get_db)):
    return []

# 2. Register in routers/__init__.py
from . import my_resource

# 3. Register in main.py
app.include_router(my_resource.router)
```

---

## Router List

| Router | Endpoints | Lines | Status |
|--------|-----------|-------|--------|
| contacts | 5 | 84 | ✅ Complete |
| users | 8 | 454 | ✅ Complete |
| events | 8 | 205 | ✅ Complete |
| interactions | 6 | 229 | ✅ Complete |
| calendars | 7 | 121 | ✅ Complete |
| calendar_memberships | 5 | 102 | ✅ Complete |
| groups | 5 | 79 | ✅ Complete |
| group_memberships | 4 | 83 | ✅ Complete |
| recurring_configs | 5 | 86 | ✅ Complete |
| event_bans | 4 | 88 | ✅ Complete |
| user_blocks | 4 | 83 | ✅ Complete |
| app_bans | 4 | 82 | ✅ Complete |
| **TOTAL** | **83** | **1,831** | **✅ 100%** |
