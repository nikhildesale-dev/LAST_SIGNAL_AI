"""schemas/report.py — Pydantic models for the hazard_reports domain."""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class ReportCreate(BaseModel):
    """Matches HazardReport.toJson() sent from Flutter."""
    id: str
    hazardType: str
    description: str
    severity: str
    sampleLocation: str
    latitude: float
    longitude: float
    timestamp: str
    status: str = "Submitted"
    syncStatus: str = "synced"
    reporterEmail: str
    responderNotes: Optional[str] = None
    verifiedBy: Optional[str] = None
    isDraft: bool = False
    photoPlaceholder: Optional[str] = None


class ReportOut(BaseModel):
    """Returned to Flutter — must match HazardReport.fromJson() field names."""
    model_config = ConfigDict(populate_by_name=True)

    id: str
    hazardType: str
    description: str
    severity: str
    sampleLocation: str
    latitude: float
    longitude: float
    timestamp: str
    status: str
    syncStatus: str
    reporterEmail: str
    responderNotes: Optional[str] = None
    verifiedBy: Optional[str] = None
    isDraft: bool
    photoPlaceholder: Optional[str] = None


class ReviewAction(BaseModel):
    responderNote: Optional[str] = None


class VerifyAction(BaseModel):
    responderName: str
    responderNote: Optional[str] = None


class RejectAction(BaseModel):
    reason: str


class ResolveAction(BaseModel):
    resolutionNote: Optional[str] = None


class SyncRequest(BaseModel):
    """Bulk offline-sync: Flutter sends list of localOnly reports."""
    reports: list[ReportCreate]
