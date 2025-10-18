# Agenda Phoenix

**Version:** 2.0.0

A modern calendar and event management system with modular architecture.

---

## 📚 Documentation

**All documentation is in the [`docs/`](docs/) folder.**

- [**Project Overview**](docs/project-overview.md)
- [**Development Rules**](docs/development-rules.md)
- [**Backend Documentation**](docs/backend/)
- [**CLI Documentation**](docs/cli/)

---

## 🚀 Quick Start

### Backend (FastAPI)
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8001

# Access API docs
open http://localhost:8001/docs
```

### CLI (Testing/Design)
```bash
cd cli
python3 menu.py
```

### Frontend (Flutter - iOS)
```bash
cd app_flutter
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
agenda_phoenix/
├── backend/           # FastAPI backend (83 endpoints, 12 routers)
├── cli/               # Python CLI for testing (pure API client)
├── app_flutter/       # Flutter mobile app (iOS)
├── app_rn/            # React Native (deprecated)
└── docs/              # 📚 All documentation here
    ├── backend/
    ├── cli/
    ├── frontend/
    └── architecture/
```

---

## 🔑 Key Features

### Backend
- **Modular Router System** - 12 routers, 83 endpoints
- **3-Level Ban System** - Event, User, and App bans
- **Recurring Events** - With hierarchical invitations
- **Conflict Detection** - Automatic event conflict checking

### CLI
- **Pure API Client** - Zero business logic
- **Design Tool** - For backend testing and design
- **Utility Functions** - Table display, formatting

---

## 🌐 API Endpoints

**Total:** 83 endpoints

See [API Endpoints](docs/backend/api-endpoints.md) for complete list.

**Available at:** `http://localhost:8001`
- **API Docs:** `/docs`
- **Health Check:** `/health`

---

## 🏗️ Architecture

### Backend (FastAPI + PostgreSQL)
- Modular router system
- SQLAlchemy ORM
- Pydantic schemas
- 12 data models

### CLI (Python)
- Menu-based interface
- Pure API client (no business logic)
- Display utilities

### Frontend (Flutter)
- iOS mobile app
- Material Design
- Provider state management

---

## 📊 Statistics

- **Backend**: 1,831 lines (modular), 83 endpoints
- **CLI**: 1,550 lines (pure client)
- **Routers**: 12 (contacts, users, events, etc.)
- **Models**: 12 (SQLAlchemy)

---

## 🔗 Related Links

- [Backend Router System](docs/backend/router-system.md)
- [3-Level Ban System](docs/backend/ban-system.md)
- [CLI Guide](docs/cli/cli-guide.md)
- [Development Rules](docs/development-rules.md)

---

## 📝 License

Private project for EventyPop.
