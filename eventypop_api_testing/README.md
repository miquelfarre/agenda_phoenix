# EventyPop API Testing

API testing tool for EventyPop - test endpoints with different users and verify integration flows.

## 🚀 Quick Start

```bash
# From project root, start with Docker
./start.sh api_testing

# Or manually
cd eventypop_api_testing
npm install
npm run dev
```

Open [http://localhost:3002](http://localhost:3002)

## ✨ Features

### User Management
- **25 Test Users** pre-configured (10 private + 15 public)
- Quick switch between users
- Separate views for private vs public users
- Auto-sets `X-User-ID` header based on selected user

### Endpoint Testing
- **45+ Endpoints** organized by category:
  - 👤 Users (get, update, current user)
  - 📅 Events (create, list, invite, RSVP)
  - 🗓️ Calendars (subscribe, discover by hash)
  - 👥 Groups (create, add members)
  - 📇 Contacts (list, add)
  - 🔔 Interactions (invitations, responses)
- **Smart Filtering**: Shows only endpoints available for selected user type
- **Category Navigation**: Filter by Users, Events, Calendars, etc.
- **Search**: Quick find endpoints by name

### Request Builder
- **Auto-complete** forms for path, query, and body parameters
- **Type Validation**: String, number, boolean, date, array
- **Required Field** indicators
- **Example Values** for quick testing
- **Live URL Preview**: See final URL before sending

### Response Viewer
- **Formatted JSON** with syntax highlighting
- **Status Code** with color coding (success/error)
- **Response Time** in milliseconds
- **Error Display** with detailed messages
- **Copy/Paste** friendly format

## 📋 Test Users

### Private Users (ID 1-10)
```
1  - Sonia Martínez    (+34600000001)  [Default user]
2  - Miquel Farré      (+34600000002)
3  - Ada Martínez      (+34600000003)
4  - Sara Rodríguez    (+34600000004)
...
```

### Public Users (ID 86-100)
```
86  - FC Barcelona        (@fcbarcelona)
87  - Teatro Nacional     (@teatrebarcelona)
88  - Gimnasio FitZone    (@fitzonegym)
89  - Restaurante         (@saborcatalunya)
...
```

## 🎯 Example Workflows

### Test Private Event Creation
1. Select **Sonia Martínez** (ID 1)
2. Choose **Create Event** endpoint
3. Fill in: name, description, start_date
4. Click "Send Request"
5. Verify event created with 200 status

### Test Public Event Discovery
1. Select **FC Barcelona** (ID 86)
2. Choose **Create Public Event**
3. Create event with max_attendees
4. Switch to **Sonia Martínez**
5. Test **Discover Public Events**
6. Verify event appears in list

### Test Calendar Subscription
1. Select any user
2. Choose **Discover Calendar by Hash**
3. Enter hash: `fcb25_26` (FC Barcelona calendar)
4. Test **Subscribe to Calendar**
5. Verify subscription created

## 🛠️ Tech Stack

- **Next.js 15** with App Router + TypeScript
- **Tailwind CSS** (pure, no UI library)
- **Axios** for HTTP requests
- Custom API client with automatic user context

## 📡 API Configuration

Default API endpoint: `http://localhost:8001`

To change:
```typescript
// lib/api-client.ts
const apiClient = new APIClient('http://your-api-url');
```

## 🔧 Adding New Endpoints

Edit `lib/endpoints.ts`:

```typescript
{
  id: 'my-endpoint',
  name: 'My Endpoint',
  method: 'POST',
  path: '/api/v1/my-endpoint',
  category: 'events',
  userType: 'private',
  description: 'Does something cool',
  bodyParams: [
    { name: 'field', type: 'string', required: true, example: 'value' }
  ]
}
```

## 🎨 UI Layout

```
┌──────────────┬────────────────┬─────────────────────────┐
│              │                │                         │
│  User        │  Endpoint      │  Endpoint Tester        │
│  Selector    │  Explorer      │                         │
│              │                │  ┌─────────────────┐    │
│  👤 Private  │  📋 All (45)   │  │ Request Builder │    │
│  🏢 Public   │  👤 Users      │  └─────────────────┘    │
│              │  📅 Events     │  ┌─────────────────┐    │
│  [Users]     │  🗓️ Calendars  │  │ Response Viewer │    │
│              │  ...           │  └─────────────────┘    │
│              │                │                         │
│  Selected:   │  [Endpoints]   │  [Testing Area]         │
│  Sonia (1)   │                │                         │
└──────────────┴────────────────┴─────────────────────────┘
```

## 📝 Notes

- Backend must be running on `localhost:8001`
- Uses test data from `init_db_2.py` (100 users)
- No authentication - uses `X-User-ID` header for testing
- Responses are NOT saved between refreshes
