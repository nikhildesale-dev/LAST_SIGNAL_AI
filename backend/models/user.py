"""models/user.py — Raw sqlite3 CRUD helpers for the users table."""

from __future__ import annotations

import sqlite3
from typing import Optional

from schemas.user import UserOut


# ---------------------------------------------------------------------------
# Row → schema conversion
# ---------------------------------------------------------------------------
def _row_to_user_out(row: sqlite3.Row) -> UserOut:
    return UserOut(
        id=row["id"],
        name=row["name"],
        email=row["email"],
        role=row["role"],
        isApproved=bool(row["is_approved"]),
        isEnabled=bool(row["is_enabled"]),
        emergencyContactName=row["emergency_contact_name"],
        emergencyContactPhone=row["emergency_contact_phone"],
        organization=row["organization"],
        createdAt=row["created_at"],
    )


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------
def get_all_users(conn: sqlite3.Connection) -> list[UserOut]:
    rows = conn.execute("SELECT * FROM users ORDER BY created_at DESC").fetchall()
    return [_row_to_user_out(r) for r in rows]


def get_user_by_email(conn: sqlite3.Connection, email: str) -> Optional[sqlite3.Row]:
    """Returns the raw row (including password_hash) or None."""
    return conn.execute(
        "SELECT * FROM users WHERE LOWER(email) = LOWER(?)", (email,)
    ).fetchone()


def get_user_by_id(conn: sqlite3.Connection, user_id: str) -> Optional[sqlite3.Row]:
    return conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()


def create_user(conn: sqlite3.Connection, *, id: str, name: str, email: str,
                password_hash: str, role: str, is_approved: bool, is_enabled: bool,
                emergency_contact_name: Optional[str], emergency_contact_phone: Optional[str],
                organization: Optional[str], created_at: str) -> None:
    conn.execute(
        """
        INSERT INTO users
            (id, name, email, password_hash, role, is_approved, is_enabled,
             emergency_contact_name, emergency_contact_phone, organization, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (id, name, email, password_hash, role,
         int(is_approved), int(is_enabled),
         emergency_contact_name, emergency_contact_phone, organization, created_at),
    )


def set_approved(conn: sqlite3.Connection, user_id: str, approved: bool) -> bool:
    result = conn.execute(
        "UPDATE users SET is_approved = ? WHERE id = ?", (int(approved), user_id)
    )
    return result.rowcount > 0


def toggle_enabled(conn: sqlite3.Connection, user_id: str) -> bool:
    result = conn.execute(
        "UPDATE users SET is_enabled = NOT is_enabled WHERE id = ?", (user_id,)
    )
    return result.rowcount > 0


def email_exists(conn: sqlite3.Connection, email: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM users WHERE LOWER(email) = LOWER(?)", (email,)
    ).fetchone()
    return row is not None
