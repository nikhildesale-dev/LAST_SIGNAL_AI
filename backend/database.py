"""
database.py — SQLite connection management and table initialisation.

All tables are created with IF NOT EXISTS so the module is safe to import
multiple times.  Call `init_db()` once at application startup.
"""

import sqlite3
import threading
from pathlib import Path

DB_PATH = Path(__file__).parent / "last_signal.db"

# Thread-local storage so each thread gets its own connection
_local = threading.local()


def get_connection() -> sqlite3.Connection:
    """Return a per-thread SQLite connection (creates one if needed)."""
    if not hasattr(_local, "conn") or _local.conn is None:
        conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
        conn.row_factory = sqlite3.Row          # rows behave like dicts
        conn.execute("PRAGMA journal_mode=WAL")  # better concurrent reads
        conn.execute("PRAGMA foreign_keys=ON")
        _local.conn = conn
    return _local.conn


def get_db():
    """FastAPI dependency that yields a connection and commits on success."""
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise


def init_db() -> None:
    """Create all tables.  Safe to call multiple times."""
    conn = get_connection()
    cursor = conn.cursor()

    # ------------------------------------------------------------------
    # users
    # ------------------------------------------------------------------
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id                      TEXT PRIMARY KEY,
            name                    TEXT NOT NULL,
            email                   TEXT UNIQUE NOT NULL,
            password_hash           TEXT NOT NULL,
            role                    TEXT NOT NULL DEFAULT 'citizen',
            is_approved             INTEGER NOT NULL DEFAULT 1,
            is_enabled              INTEGER NOT NULL DEFAULT 1,
            emergency_contact_name  TEXT,
            emergency_contact_phone TEXT,
            organization            TEXT,
            created_at              TEXT NOT NULL
        )
    """)

    # ------------------------------------------------------------------
    # hazard_reports
    # ------------------------------------------------------------------
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS hazard_reports (
            id                TEXT PRIMARY KEY,
            hazard_type       TEXT NOT NULL,
            description       TEXT NOT NULL,
            severity          TEXT NOT NULL,
            sample_location   TEXT NOT NULL,
            latitude          REAL NOT NULL,
            longitude         REAL NOT NULL,
            timestamp         TEXT NOT NULL,
            status            TEXT NOT NULL DEFAULT 'Submitted',
            sync_status       TEXT NOT NULL DEFAULT 'synced',
            reporter_email    TEXT NOT NULL,
            responder_notes   TEXT,
            verified_by       TEXT,
            is_draft          INTEGER NOT NULL DEFAULT 0,
            photo_placeholder TEXT
        )
    """)

    # ------------------------------------------------------------------
    # emergency_locations
    # ------------------------------------------------------------------
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS emergency_locations (
            id                 TEXT PRIMARY KEY,
            name               TEXT NOT NULL,
            type               TEXT NOT NULL,
            sample_address     TEXT NOT NULL,
            distance_km        REAL NOT NULL DEFAULT 0.0,
            latitude           REAL NOT NULL,
            longitude          REAL NOT NULL,
            capacity           INTEGER NOT NULL DEFAULT 0,
            occupied           INTEGER NOT NULL DEFAULT 0,
            contact_phone      TEXT NOT NULL DEFAULT '',
            is_open            INTEGER NOT NULL DEFAULT 1,
            is_saved_offline   INTEGER NOT NULL DEFAULT 1,
            available_services TEXT NOT NULL DEFAULT '[]'
        )
    """)

    # ------------------------------------------------------------------
    # notifications
    # ------------------------------------------------------------------
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS notifications (
            id                TEXT PRIMARY KEY,
            user_email        TEXT NOT NULL,
            title             TEXT NOT NULL,
            message           TEXT NOT NULL,
            type              TEXT NOT NULL DEFAULT 'riskUpdate',
            timestamp         TEXT NOT NULL,
            is_read           INTEGER NOT NULL DEFAULT 0,
            related_report_id TEXT
        )
    """)

    conn.commit()
