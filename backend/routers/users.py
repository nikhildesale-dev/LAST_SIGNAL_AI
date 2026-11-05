"""routers/users.py — Admin user management on /api/users"""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, HTTPException

from database import get_db
from models import user as user_model
from schemas.user import UserOut

router = APIRouter(prefix="/api/users", tags=["users"])


@router.get("", response_model=list[UserOut])
def list_users(conn: sqlite3.Connection = Depends(get_db)):
    """Admin: list all registered users."""
    return user_model.get_all_users(conn)


@router.patch("/{user_id}/approve", response_model=UserOut)
def approve_responder(user_id: str, conn: sqlite3.Connection = Depends(get_db)):
    """Admin: approve a pending responder application."""
    ok = user_model.set_approved(conn, user_id, approved=True)
    if not ok:
        raise HTTPException(status_code=404, detail="User not found.")
    row = user_model.get_user_by_id(conn, user_id)
    return UserOut(
        id=row["id"], name=row["name"], email=row["email"], role=row["role"],
        isApproved=bool(row["is_approved"]), isEnabled=bool(row["is_enabled"]),
        emergencyContactName=row["emergency_contact_name"],
        emergencyContactPhone=row["emergency_contact_phone"],
        organization=row["organization"], createdAt=row["created_at"],
    )


@router.patch("/{user_id}/reject", response_model=UserOut)
def reject_responder(user_id: str, conn: sqlite3.Connection = Depends(get_db)):
    """Admin: reject / revoke a responder's approval."""
    ok = user_model.set_approved(conn, user_id, approved=False)
    if not ok:
        raise HTTPException(status_code=404, detail="User not found.")
    row = user_model.get_user_by_id(conn, user_id)
    return UserOut(
        id=row["id"], name=row["name"], email=row["email"], role=row["role"],
        isApproved=bool(row["is_approved"]), isEnabled=bool(row["is_enabled"]),
        emergencyContactName=row["emergency_contact_name"],
        emergencyContactPhone=row["emergency_contact_phone"],
        organization=row["organization"], createdAt=row["created_at"],
    )


@router.patch("/{user_id}/toggle", response_model=UserOut)
def toggle_account_status(user_id: str, conn: sqlite3.Connection = Depends(get_db)):
    """Admin: enable or disable a user account."""
    ok = user_model.toggle_enabled(conn, user_id)
    if not ok:
        raise HTTPException(status_code=404, detail="User not found.")
    row = user_model.get_user_by_id(conn, user_id)
    return UserOut(
        id=row["id"], name=row["name"], email=row["email"], role=row["role"],
        isApproved=bool(row["is_approved"]), isEnabled=bool(row["is_enabled"]),
        emergencyContactName=row["emergency_contact_name"],
        emergencyContactPhone=row["emergency_contact_phone"],
        organization=row["organization"], createdAt=row["created_at"],
    )
