# Agenda Phoenix

A modern full-stack application featuring Flutter, FastAPI, Supabase, and real-time synchronization with Hive local storage.

## Architecture

- **Frontend**: Flutter (iOS) with Provider state management
- **Local Storage**: Hive for offline-first architecture
- **Backend**: FastAPI REST API
- **Database**: Supabase (PostgreSQL with Realtime)
- **Real-time Sync**: Supabase Realtime for automatic data synchronization

## Features

- Real-time event synchronization across devices
- Offline-first architecture with Hive local storage
- Repository Pattern for clean architecture
- Automatic cache management
- Full CRUD operations on events
- Beautiful Material Design UI

## Project Structure

```
agenda_phoenix/
├── app_flutter/          # Flutter mobile app
│   ├── lib/
│   │   ├── models/       # Data models (Event with Hive)
│   │   ├── repositories/ # Repository Pattern implementation
│   │   ├── providers/    # State management (Provider)
│   │   ├── services/     # Supabase service
│   │   └── screens/      # UI screens
│   └── pubspec.yaml
├── backend/              # FastAPI backend
│   ├── main.py          # FastAPI application
│   ├── requirements.txt # Python dependencies
│   ├── Dockerfile       # Backend Docker image
│   ├── config/          # Kong API Gateway config
│   └── sql/             # Database initialization scripts
├── docker-compose.yml   # All services configuration
├── .env.example         # Environment variables template
└── start_phoenix.sh     # Automated startup script
```

## Quick Start

### Prerequisites

- Docker Desktop
- Flutter SDK (latest version)
- Xcode (for iOS development)
- Command Line Tools

### Installation

1. **Clone the repository** (if not already done)

2. **Start all services**:
   ```bash
   ./start_phoenix.sh
   ```

This command will:
- Start Supabase (PostgreSQL + Realtime + Auth + Storage + Studio)
- Start FastAPI backend
- Clean Flutter cache
- Launch iOS simulator
- Run the Flutter app with Realtime sync

### Manual Commands

Start only backend services:
```bash
./start_phoenix.sh backend
```

Start only iOS app:
```bash
./start_phoenix.sh ios
```

Stop all services:
```bash
./start_phoenix.sh stop
```

Check services status:
```bash
./start_phoenix.sh status
```

## Services & Ports

After starting with `./start_phoenix.sh backend`:

- **Supabase Studio**: http://localhost:3000 (Database UI)
- **Supabase API**: http://localhost:8000 (REST + Realtime)
- **Backend API**: http://localhost:8001 (FastAPI)
- **PostgreSQL**: localhost:5432

## API Endpoints

### Backend FastAPI (localhost:8001)

- `GET /` - API information
- `GET /health` - Health check
- `GET /events` - Get all events
- `GET /events/{id}` - Get single event
- `POST /events` - Create new event
- `PUT /events/{id}` - Update event
- `DELETE /events/{id}` - Delete event

### Supabase API (localhost:8000)

- REST API: http://localhost:8000/rest/v1/
- Realtime: ws://localhost:8000/realtime/v1/
- Auth: http://localhost:8000/auth/v1/
- Storage: http://localhost:8000/storage/v1/

## Development

### Flutter App

The app uses:
- **Supabase Flutter SDK** for backend connection and Realtime
- **Hive** for local storage and offline support
- **Provider** for state management
- **Repository Pattern** for clean architecture

Real-time updates are automatic - any change in the database immediately reflects in the app.

### Testing Realtime

1. Open the app on iOS simulator
2. Open Supabase Studio at http://localhost:3000
3. Go to Table Editor → events
4. Add, edit, or delete events
5. Watch the app update automatically in real-time!

### Database Schema

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## Environment Variables

Copy `.env.example` to `.env` and adjust if needed:

```bash
cp .env.example .env
```

Key variables:
- `POSTGRES_PASSWORD`: Database password
- `JWT_SECRET`: JWT token secret
- `ANON_KEY`: Supabase anonymous key
- `SERVICE_ROLE_KEY`: Supabase service role key

## Troubleshooting

### Port already in use
If ports 8000, 8001, 3000, or 5432 are in use:
```bash
./start_phoenix.sh stop
# Then try again
./start_phoenix.sh
```

### Flutter build issues
```bash
cd app_flutter
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### Docker issues
```bash
docker compose down -v  # Remove volumes
docker compose build --no-cache
```

### Simulator not found
Make sure Xcode and iOS Simulator are installed:
```bash
xcode-select --install
open -a Simulator
```

## Technology Stack

- **Frontend**: Flutter 3.x, Dart
- **State Management**: Provider
- **Local Database**: Hive
- **Backend**: FastAPI, Python 3.11
- **Database**: PostgreSQL 15 (Supabase)
- **Real-time**: Supabase Realtime
- **API Gateway**: Kong
- **Auth**: GoTrue (Supabase Auth)
- **Containerization**: Docker, Docker Compose

## Next Steps

This is a POC ready to be extended with:
- User authentication
- More complex data models (6-7 tables as planned)
- File uploads with Supabase Storage
- Push notifications
- Android support
- Web support

## License

Private project for POC purposes.

