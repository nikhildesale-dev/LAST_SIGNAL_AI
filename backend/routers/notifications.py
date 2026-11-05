"""routers/notifications.py — GET /api/notifications"""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, Query

from database import get_db
from models import notification as notif_model
from schemas.notification import NotificationOut

router = APIRouter(prefix="/api", tags=["notifications"])


@router.get("/notifications", response_model=list[NotificationOut])
def get_notifications(
    user_email: str = Query(..., description="Email of the authenticated user"),
    conn: sqlite3.Connection = Depends(get_db),
):
    """
    Return notifications for the given user.
    The Flutter NotificationProvider sends the logged-in user's email as a query param.
    """
    return notif_model.get_notifications_for_user(conn, user_email)
