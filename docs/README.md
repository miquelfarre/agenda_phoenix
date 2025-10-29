# Agenda Phoenix - Documentation

**Version:** 2.0.0
**Last Updated:** 2025-10-18

---

## 📚 Documentation Index

### 🎯 Getting Started
- [**Project Overview**](project-overview.md) - High-level architecture and goals
- [**Development Rules**](development-rules.md) - CLI vs Backend separation, best practices

### 🔧 Backend
- [**API Endpoints**](backend/api-endpoints.md) - Complete list of 83 API endpoints
- [**Router System**](backend/router-system.md) - Modular architecture
- [**Ban System**](backend/ban-system.md) - Event, User, and App bans
- [**Database Models**](backend/models.md) - Data structure

### 💻 CLI
- [**CLI Guide**](cli/cli-guide.md) - How to use the CLI
- [**CLI Structure**](cli/structure.md) - Files and organization

### 📱 Frontend
- [**Flutter App**](frontend/flutter.md) - Mobile app (Flutter)
- [**React Native**](frontend/react-native.md) - Mobile app (RN) - deprecated
- [**Realtime Sync Standard**](frontend/realtime.md) - Pattern used across repositories

### 🏗️ Architecture
- [**System Architecture**](architecture/system.md) - Overall system design
- [**Refactoring History**](architecture/refactoring.md) - Major changes log

---

## 🚀 Quick Start

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8001
```

### CLI
```bash
cd cli
python3 menu.py
```

### Frontend (Flutter)
```bash
cd app_flutter
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
agenda_phoenix/
├── backend/           # FastAPI backend (modular routers)
├── cli/               # Python CLI for design/testing
├── app_flutter/       # Flutter mobile app
├── app_rn/            # React Native (deprecated)
└── docs/              # This documentation
    ├── backend/
    ├── cli/
    ├── frontend/
    └── architecture/
```

---

## 🔑 Key Concepts

### 1. Separation of Concerns
- **Backend**: All business logic, validation, and data processing
- **CLI**: Pure API client for testing/design (NO business logic)
- **Frontend**: User interface (consumes backend API)

### 2. Router Architecture
Backend organized in modular routers:
- contacts, users, events, interactions
- calendars, calendar_memberships
- groups, group_memberships
- recurring_configs, event_bans, user_blocks, app_bans

### 3. Ban System (3 Levels)
1. **Event Ban**: Ban user from specific event (owner)
2. **User Block**: Block user from all your events (user)
3. **App Ban**: Ban user from entire app (admin)

---

## 📊 Project Statistics

- **Backend**: 83 API endpoints, 12 routers, ~1,800 LOC
- **CLI**: Pure API client, ~1,550 LOC
- **Database**: 12 models (SQLAlchemy + PostgreSQL)

---

## 🤝 Contributing

See [Development Rules](development-rules.md) for guidelines.

---

## 📝 Documentation Standards

- Keep docs updated when changing code
- Use markdown for all documentation
- Include code examples where helpful
- Document API changes in changelog
