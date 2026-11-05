# LAST SIGNAL AI — Python/FastAPI Backend

## Quick Start

```bash
# 1. Navigate to the backend directory
cd backend

# 2. Create and activate a virtual environment
python -m venv .venv
# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Start the server (auto-seeds the DB on first run)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The server starts on **http://localhost:8000**

- Interactive API docs: http://localhost:8000/docs
- Health check: http://localhost:8000/api/health

---

## Project Structure

```
backend/
├── main.py                    # FastAPI app, CORS, router wiring, lifespan
├── database.py                # SQLite connection + table creation
├── seed.py                    # Seeds mock data matching Flutter mock files
├── requirements.txt
├── models/
│   ├── user.py                # CRUD helpers for `users` table
│   ├── report.py              # CRUD helpers for `hazard_reports` table
│   ├── location.py            # CRUD helpers for `emergency_locations` table
│   └── notification.py        # CRUD helpers for `notifications` table
├── schemas/
│   ├── user.py                # Pydantic: Login/Register request + UserOut
│   ├── report.py              # Pydantic: ReportCreate, ReportOut, triage actions
│   ├── risk.py                # Pydantic: RiskPredictRequest/Response
│   ├── location.py            # Pydantic: LocationOut
│   └── notification.py        # Pydantic: NotificationOut
├── routers/
│   ├── health.py              # GET  /api/health
│   ├── auth.py                # POST /api/auth/login  /api/auth/register
│   ├── reports.py             # GET/POST /api/reports + PATCH triage actions
│   ├── users.py               # GET /api/users + PATCH approve/reject/toggle
│   ├── risk.py                # POST /api/predict-risk
│   ├── locations.py           # GET  /api/locations
│   └── notifications.py       # GET  /api/notifications
└── services/
    └── risk_engine.py         # Heuristic AI risk scoring engine
```

---

## API Endpoints

### Health
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/health` | Backend ping / health check |

### Auth
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/auth/login` | Authenticate (citizen / responder / admin) |
| `POST` | `/api/auth/register` | Self-register a new citizen account |

### Reports
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/reports` | Fetch all synced hazard reports |
| `POST` | `/api/reports` | Submit a new hazard report |
| `POST` | `/api/reports/sync` | Bulk sync offline (localOnly) reports |
| `PATCH` | `/api/reports/{id}/review` | Mark report as "Under Review" |
| `PATCH` | `/api/reports/{id}/verify` | Verify a report |
| `PATCH` | `/api/reports/{id}/reject` | Reject a report |
| `PATCH` | `/api/reports/{id}/resolve` | Mark report as Resolved |

### Users (Admin)
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/users` | List all users |
| `PATCH` | `/api/users/{id}/approve` | Approve a pending responder |
| `PATCH` | `/api/users/{id}/reject` | Reject / revoke a responder |
| `PATCH` | `/api/users/{id}/toggle` | Enable / disable an account |

### Risk AI
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/predict-risk` | AI risk prediction for lat/lon |

### Emergency Locations
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/locations` | Fetch all emergency locations |

### Notifications
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/notifications?user_email=` | Fetch notifications for a user |

---

## Demo Credentials (seeded automatically)

| Role | Email | Password |
|------|-------|----------|
| Citizen | `citizen@lastsignal.demo` | `citizen123` |
| Responder (approved) | `responder@lastsignal.demo` | `responder123` |
| Admin | `admin@lastsignal.demo` | `admin123` |
| Responder (pending) | `jordan.kelly@coastal-rescue.org` | `responder123` |

---

## Database

SQLite file is created at `backend/last_signal.db` on first startup.

To reseed (wipe and repopulate mock data):
```bash
python seed.py --force
```

---

## Flutter Connection

The Flutter app connects to `http://localhost:8000` by default (configured in
`ApiService.defaultLocalUrl`). On Android emulator it uses `http://10.0.2.2:8000`.
Both are allowed by the CORS middleware.
