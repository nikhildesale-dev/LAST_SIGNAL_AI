"""routers/reports.py — CRUD + triage actions on /api/reports"""

from __future__ import annotations

import sqlite3
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from database import get_db
from models import report as report_model
from schemas.report import (
    RejectAction,
    ReportCreate,
    ReportOut,
    ResolveAction,
    ReviewAction,
    SyncRequest,
    VerifyAction,
)

router = APIRouter(prefix="/api/reports", tags=["reports"])


# ---------------------------------------------------------------------------
# GET /api/reports
# Called by ApiService.fetchReportsFromBackend()
# ---------------------------------------------------------------------------
@router.get("", response_model=list[ReportOut])
def fetch_reports(conn: sqlite3.Connection = Depends(get_db)):
    """Return all synced, non-draft reports."""
    return report_model.get_synced_reports(conn)


# ---------------------------------------------------------------------------
# POST /api/reports
# Called by ApiService.submitReportToBackend()
# ---------------------------------------------------------------------------
@router.post("", response_model=ReportOut, status_code=201)
def submit_report(body: ReportCreate, conn: sqlite3.Connection = Depends(get_db)):
    """
    Accept a single report from a citizen.
    The Flutter client sends status='Submitted', syncStatus='synced'.
    """
    # Force to synced/Submitted when received by backend
    body = body.model_copy(update={"syncStatus": "synced", "status": "Submitted"})
    report_model.upsert_report(conn, body)
    result = report_model.get_report_by_id(conn, body.id)
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to persist report.")
    return result


# ---------------------------------------------------------------------------
# POST /api/reports/sync
# Called when Flutter simulates reconnection (ReportProvider.syncPendingReports)
# ---------------------------------------------------------------------------
@router.post("/sync", response_model=list[ReportOut])
def sync_reports(body: SyncRequest, conn: sqlite3.Connection = Depends(get_db)):
    """
    Bulk upsert of offline (localOnly) reports.
    All incoming reports are promoted to syncStatus='synced', status='Submitted'.
    Returns the full updated list of synced reports.
    """
    for r in body.reports:
        promoted = r.model_copy(update={"syncStatus": "synced", "status": "Submitted",
                                        "isDraft": False})
        report_model.upsert_report(conn, promoted)
    return report_model.get_synced_reports(conn)


# ---------------------------------------------------------------------------
# Responder triage actions
# ---------------------------------------------------------------------------
@router.patch("/{report_id}/review", response_model=ReportOut)
def mark_under_review(report_id: str, body: ReviewAction,
                      conn: sqlite3.Connection = Depends(get_db)):
    """Responder: mark report as 'Under Review'."""
    ok = report_model.update_report_status(
        conn, report_id,
        status="Under Review",
        responder_notes=body.responderNote,
    )
    if not ok:
        raise HTTPException(status_code=404, detail="Report not found.")
    return report_model.get_report_by_id(conn, report_id)


@router.patch("/{report_id}/verify", response_model=ReportOut)
def verify_report(report_id: str, body: VerifyAction,
                  conn: sqlite3.Connection = Depends(get_db)):
    """Responder: verify a report."""
    ok = report_model.update_report_status(
        conn, report_id,
        status="Verified",
        responder_notes=body.responderNote,
        verified_by=body.responderName,
    )
    if not ok:
        raise HTTPException(status_code=404, detail="Report not found.")
    return report_model.get_report_by_id(conn, report_id)


@router.patch("/{report_id}/reject", response_model=ReportOut)
def reject_report(report_id: str, body: RejectAction,
                  conn: sqlite3.Connection = Depends(get_db)):
    """Responder: reject a report."""
    ok = report_model.update_report_status(
        conn, report_id,
        status="Rejected",
        responder_notes=body.reason,
    )
    if not ok:
        raise HTTPException(status_code=404, detail="Report not found.")
    return report_model.get_report_by_id(conn, report_id)


@router.patch("/{report_id}/resolve", response_model=ReportOut)
def resolve_report(report_id: str, body: ResolveAction,
                   conn: sqlite3.Connection = Depends(get_db)):
    """Responder: mark report as resolved."""
    ok = report_model.update_report_status(
        conn, report_id,
        status="Resolved",
        responder_notes=body.resolutionNote,
    )
    if not ok:
        raise HTTPException(status_code=404, detail="Report not found.")
    return report_model.get_report_by_id(conn, report_id)
