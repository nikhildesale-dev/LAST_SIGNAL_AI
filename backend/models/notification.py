"""models/notification.py — Raw sqlite3 CRUD helpers for notifications."""

from __future__ import annotations

import sqlite3
from typing import Optional

from schemas.notification import NotificationOut


def _row_to_notification_out(row: sqlite3.Row) -> NotificationOut:
    return NotificationOut(
        id=row["id"],
        title=row["title"],
        message=row["message"],
        type=row["type"],
        timestamp=row["timestamp"],
        isRead=bool(row["is_read"]),
        relatedReportId=row["related_report_id"],
    )


def get_notifications_for_user(conn: sqlite3.Connection,
                                user_email: str) -> list[NotificationOut]:
    rows = conn.execute(
        """SELECT * FROM notifications
           WHERE LOWER(user_email) = LOWER(?)
           ORDER BY timestamp DESC
           LIMIT 100""",
        (user_email,),
    ).fetchall()
    return [_row_to_notification_out(r) for r in rows]


def insert_notification(conn: sqlite3.Connection, *, id: str, user_email: str,
                        title: str, message: str, type: str, timestamp: str,
                        related_report_id: Optional[str] = None) -> None:
    conn.execute(
        """
        INSERT OR IGNORE INTO notifications
            (id, user_email, title, message, type, timestamp, is_read, related_report_id)
        VALUES (?, ?, ?, ?, ?, ?, 0, ?)
        """,
        (id, user_email, title, message, type, timestamp, related_report_id),
    )


def mark_all_read(conn: sqlite3.Connection, user_email: str) -> None:
    conn.execute(
        "UPDATE notifications SET is_read = 1 WHERE LOWER(user_email) = LOWER(?)",
        (user_email,),
    )
