"""models/report.py — Raw sqlite3 CRUD helpers for the hazard_reports table."""

from __future__ import annotations

import sqlite3
from typing import Optional

from schemas.report import ReportCreate, ReportOut


# ---------------------------------------------------------------------------
# Row → schema conversion
# ---------------------------------------------------------------------------
def _row_to_report_out(row: sqlite3.Row) -> ReportOut:
    return ReportOut(
        id=row["id"],
        hazardType=row["hazard_type"],
        description=row["description"],
        severity=row["severity"],
        sampleLocation=row["sample_location"],
        latitude=row["latitude"],
        longitude=row["longitude"],
        timestamp=row["timestamp"],
        status=row["status"],
        syncStatus=row["sync_status"],
        reporterEmail=row["reporter_email"],
        responderNotes=row["responder_notes"],
        verifiedBy=row["verified_by"],
        isDraft=bool(row["is_draft"]),
        photoPlaceholder=row["photo_placeholder"],
    )


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------
def get_all_reports(conn: sqlite3.Connection) -> list[ReportOut]:
    rows = conn.execute(
        "SELECT * FROM hazard_reports ORDER BY timestamp DESC"
    ).fetchall()
    return [_row_to_report_out(r) for r in rows]


def get_synced_reports(conn: sqlite3.Connection) -> list[ReportOut]:
    """Returns only synced, non-draft reports (what Flutter fetches)."""
    rows = conn.execute(
        """SELECT * FROM hazard_reports
           WHERE sync_status = 'synced' AND is_draft = 0
           ORDER BY timestamp DESC"""
    ).fetchall()
    return [_row_to_report_out(r) for r in rows]


def get_report_by_id(conn: sqlite3.Connection, report_id: str) -> Optional[ReportOut]:
    row = conn.execute(
        "SELECT * FROM hazard_reports WHERE id = ?", (report_id,)
    ).fetchone()
    return _row_to_report_out(row) if row else None


def upsert_report(conn: sqlite3.Connection, r: ReportCreate) -> None:
    """Insert or replace a report (used for sync bulk upsert)."""
    conn.execute(
        """
        INSERT INTO hazard_reports
            (id, hazard_type, description, severity, sample_location,
             latitude, longitude, timestamp, status, sync_status,
             reporter_email, responder_notes, verified_by, is_draft, photo_placeholder)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            status         = excluded.status,
            sync_status    = excluded.sync_status,
            responder_notes= excluded.responder_notes,
            verified_by    = excluded.verified_by,
            is_draft       = excluded.is_draft
        """,
        (r.id, r.hazardType, r.description, r.severity, r.sampleLocation,
         r.latitude, r.longitude, r.timestamp, r.status, r.syncStatus,
         r.reporterEmail, r.responderNotes, r.verifiedBy, int(r.isDraft),
         r.photoPlaceholder),
    )


def insert_report(conn: sqlite3.Connection, r: ReportCreate) -> None:
    conn.execute(
        """
        INSERT OR IGNORE INTO hazard_reports
            (id, hazard_type, description, severity, sample_location,
             latitude, longitude, timestamp, status, sync_status,
             reporter_email, responder_notes, verified_by, is_draft, photo_placeholder)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (r.id, r.hazardType, r.description, r.severity, r.sampleLocation,
         r.latitude, r.longitude, r.timestamp, r.status, r.syncStatus,
         r.reporterEmail, r.responderNotes, r.verifiedBy, int(r.isDraft),
         r.photoPlaceholder),
    )


def update_report_status(conn: sqlite3.Connection, report_id: str, *,
                         status: str,
                         responder_notes: Optional[str] = None,
                         verified_by: Optional[str] = None) -> bool:
    result = conn.execute(
        """
        UPDATE hazard_reports
        SET status          = ?,
            responder_notes = COALESCE(?, responder_notes),
            verified_by     = COALESCE(?, verified_by)
        WHERE id = ?
        """,
        (status, responder_notes, verified_by, report_id),
    )
    return result.rowcount > 0


def report_id_exists(conn: sqlite3.Connection, report_id: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM hazard_reports WHERE id = ?", (report_id,)
    ).fetchone()
    return row is not None
