"""routers/auth.py — POST /api/auth/login  &  POST /api/auth/register"""

from __future__ import annotations

import sqlite3
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from database import get_db
from models import user as user_model
from schemas.user import LoginRequest, LoginResponse, RegisterRequest, RegisterResponse, UserOut

import bcrypt as _bcrypt_lib

def _hash(password: str) -> str:
    return _bcrypt_lib.hashpw(password.encode(), _bcrypt_lib.gensalt()).decode()

def _verify(plain: str, hashed: str) -> bool:
    try:
        return _bcrypt_lib.checkpw(plain.encode(), hashed.encode())
    except Exception:
        return False


router = APIRouter(prefix="/api/auth", tags=["auth"])


# ---------------------------------------------------------------------------
# Helper
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
# Routes
# ---------------------------------------------------------------------------
@router.post("/login", response_model=LoginResponse)
def login(body: LoginRequest, conn: sqlite3.Connection = Depends(get_db)):
    """
    Mirrors AuthService.login() logic:
    - Checks email + password
    - Validates role matches expectedRole
    - Checks isEnabled and isApproved for responders
    """
    row = user_model.get_user_by_email(conn, body.email)
    if row is None:
        return LoginResponse(success=False, message="Invalid credentials.")

    if not _verify(body.password, row["password_hash"]):
        return LoginResponse(success=False, message="Invalid credentials.")

    if not row["is_enabled"]:
        return LoginResponse(
            success=False,
            message="This account has been disabled by the system administrator.",
        )

    if row["role"] != body.expectedRole:
        return LoginResponse(
            success=False,
            message=f"Role mismatch: Account is registered as {row['role'].upper()}.",
        )

    if row["role"] == "responder" and not row["is_approved"]:
        return LoginResponse(
            success=False,
            message="Responder authorization pending administrative verification.",
        )

    user_out = _row_to_user_out(row)
    role_label = {"citizen": "Citizen", "responder": "Responder", "admin": "Administrator"}.get(
        row["role"], row["role"].capitalize()
    )
    return LoginResponse(
        success=True,
        message=f"Logged in as {role_label}",
        user=user_out,
    )


@router.post("/register", response_model=RegisterResponse)
def register(body: RegisterRequest, conn: sqlite3.Connection = Depends(get_db)):
    """
    Mirrors AuthService.registerCitizen().
    Only citizens can self-register; responders must be added by an admin.
    """
    if not body.name.strip():
        return RegisterResponse(success=False, message="Full name is required.")
    if "@" not in body.email or "." not in body.email:
        return RegisterResponse(success=False, message="Please enter a valid email address.")
    if len(body.password) < 6:
        return RegisterResponse(success=False, message="Password must be at least 6 characters.")
    if body.password != body.confirmPassword:
        return RegisterResponse(success=False, message="Passwords do not match.")
    if user_model.email_exists(conn, body.email):
        return RegisterResponse(
            success=False, message="An account with this email already exists."
        )

    ms = str(datetime.now(timezone.utc).timestamp()).replace(".", "")[-6:]
    user_id = f"USR-CIT-{ms}"
    now_iso = datetime.now(timezone.utc).isoformat()

    user_model.create_user(
        conn,
        id=user_id,
        name=body.name.strip(),
        email=body.email.strip().lower(),
        password_hash=_hash(body.password),
        role="citizen",
        is_approved=True,
        is_enabled=True,
        emergency_contact_name=body.emergencyContactName,
        emergency_contact_phone=body.emergencyContactPhone,
        organization=None,
        created_at=now_iso,
    )

    user_out = UserOut(
        id=user_id,
        name=body.name.strip(),
        email=body.email.strip().lower(),
        role="citizen",
        isApproved=True,
        isEnabled=True,
        emergencyContactName=body.emergencyContactName,
        emergencyContactPhone=body.emergencyContactPhone,
        organization=None,
        createdAt=now_iso,
    )
    return RegisterResponse(
        success=True,
        message="Registration complete. Welcome to LAST SIGNAL AI.",
        user=user_out,
    )
