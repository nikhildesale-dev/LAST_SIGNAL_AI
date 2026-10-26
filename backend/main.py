"""
main.py — LAST SIGNAL AI FastAPI backend entry point.

Start with:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import init_db
from seed import seed
from routers import health, auth, reports, users, risk, locations, notifications


# ---------------------------------------------------------------------------
# Lifespan: runs once at startup
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Create tables
    init_db()
    # 2. Seed mock data if DB is empty (idempotent)
    seed(force=False)
    yield
    # (shutdown logic would go here)


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="LAST SIGNAL AI — Backend",
    description=(
        "AI-driven predictive emergency routing & offline P2P disaster management. "
        "FastAPI + SQLite backend for the LAST SIGNAL AI Flutter application."
    ),
    version="1.0.0",
    lifespan=lifespan,
)


# ---------------------------------------------------------------------------
# CORS — allow Flutter web (localhost:*) and mobile (10.0.2.2)
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:8080",
        "http://localhost:5000",
        "http://localhost:3000",
        "http://10.0.2.2:8000",
        "*",  # Wide-open for prototype; restrict in production
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(reports.router)
app.include_router(users.router)
app.include_router(risk.router)
app.include_router(locations.router)
app.include_router(notifications.router)


# ---------------------------------------------------------------------------
# Root redirect info
# ---------------------------------------------------------------------------
@app.get("/", include_in_schema=False)
def root():
    return {
        "app": "LAST SIGNAL AI Backend",
        "docs": "/docs",
        "health": "/api/health",
    }
