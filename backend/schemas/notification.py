"""schemas/notification.py — Pydantic models for notifications."""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, ConfigDict


class NotificationOut(BaseModel):
    """Matches NotificationItem.fromJson() field names."""
    model_config = ConfigDict(populate_by_name=True)

    id: str
    title: str
    message: str
    type: str
    timestamp: str
    isRead: bool
    relatedReportId: Optional[str] = None
