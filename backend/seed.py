"""
seed.py — Populates the SQLite database with the same mock data
defined in the Flutter frontend (mock_users.dart, mock_reports.dart,
mock_locations.dart) so the app works out-of-the-box after first run.

Run once:
    python seed.py
Or it is called automatically by main.py on startup if tables are empty.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timedelta, timezone

# Bootstrap sys.path so relative imports work when run directly
import os
sys.path.insert(0, os.path.dirname(__file__))

from database import get_connection, init_db
from models import report as report_model
from models import user as user_model
from models import location as location_model
from models import notification as notif_model
from schemas.report import ReportCreate

import bcrypt as _bcrypt_lib

def _hash(p: str) -> str:
    return _bcrypt_lib.hashpw(p.encode(), _bcrypt_lib.gensalt()).decode()


def _iso(dt: datetime) -> str:
    return dt.isoformat()


now = datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Seed users  (mirrors mock_users.dart + AppConstants demo credentials)
# ---------------------------------------------------------------------------
SEED_USERS = [
    dict(
        id="USR-CIT-01",
        name="Maya Lin",
        email="citizen@lastsignal.demo",
        password=_hash("citizen123"),
        role="citizen",
        is_approved=True,
        is_enabled=True,
        emergency_contact_name="David Lin (Spouse)",
        emergency_contact_phone="+1 (555) 019-2834",
        organization="Resident - Sector 4",
        created_at=_iso(now - timedelta(days=30)),
    ),
    dict(
        id="USR-RSP-01",
        name="Capt. Marcus Vance",
        email="responder@lastsignal.demo",
        password=_hash("responder123"),
        role="responder",
        is_approved=True,
        is_enabled=True,
        emergency_contact_name=None,
        emergency_contact_phone=None,
        organization="Coastal Emergency Response Team (CERT-9)",
        created_at=_iso(now - timedelta(days=60)),
    ),
    dict(
        id="USR-ADM-01",
        name="Dr. Sarah Chen",
        email="admin@lastsignal.demo",
        password=_hash("admin123"),
        role="admin",
        is_approved=True,
        is_enabled=True,
        emergency_contact_name=None,
        emergency_contact_phone=None,
        organization="Emergency Intelligence Operations",
        created_at=_iso(now - timedelta(days=120)),
    ),
    dict(
        id="USR-RSP-REQ-02",
        name="Lt. Jordan Kelly",
        email="jordan.kelly@coastal-rescue.org",
        password=_hash("responder123"),
        role="responder",
        is_approved=False,  # Pending admin approval (Flow E demo)
        is_enabled=True,
        emergency_contact_name=None,
        emergency_contact_phone=None,
        organization="Marine & Flood Rescue Unit 3",
        created_at=_iso(now - timedelta(hours=4)),
    ),
    dict(
        id="USR-CIT-02",
        name="Elena Rostova",
        email="elena.rostova@metro.org",
        password=_hash("citizen123"),
        role="citizen",
        is_approved=True,
        is_enabled=True,
        emergency_contact_name="Dr. Rostova (Sister)",
        emergency_contact_phone="+1 (555) 837-1294",
        organization="Civic Volunteer Network",
        created_at=_iso(now - timedelta(days=12)),
    ),
]


# ---------------------------------------------------------------------------
# Seed reports  (mirrors mock_reports.dart)
# ---------------------------------------------------------------------------
SEED_REPORTS: list[ReportCreate] = [
    ReportCreate(
        id="REP-FLD-01",
        hazardType="Flood",
        description=(
            "Rapid storm surge flooding across 4th Avenue Underpass. "
            "Water depth estimated at 1.2 meters. Inundating electrical sub-boxes."
        ),
        severity="Critical",
        sampleLocation="4th Avenue Underpass & Shoreline Rd",
        latitude=18.9280,
        longitude=72.8310,
        timestamp=_iso(now - timedelta(minutes=42)),
        status="Verified",
        syncStatus="synced",
        reporterEmail="citizen@lastsignal.demo",
        responderNotes="CERT Team 9 confirmed impassable. Diverted traffic toward North Ridge Bypass.",
        verifiedBy="Capt. Marcus Vance",
        isDraft=False,
    ),
    ReportCreate(
        id="REP-ROD-02",
        hazardType="Blocked Road",
        description=(
            "Uprooted banyan tree and downed utility poles blocking both lanes on Hillview Drive. "
            "High risk of energized power lines."
        ),
        severity="High",
        sampleLocation="Hillview Drive, Near Mile Marker 4",
        latitude=18.9390,
        longitude=72.8270,
        timestamp=_iso(now - timedelta(hours=2, minutes=15)),
        status="Under Review",
        syncStatus="synced",
        reporterEmail="elena.rostova@metro.org",
        responderNotes="Municipal power crew dispatched for electrical isolation.",
        verifiedBy=None,
        isDraft=False,
    ),
    ReportCreate(
        id="REP-LND-03",
        hazardType="Landslide",
        description=(
            "Partial embankment collapse along Coastal Highway Sector 5. "
            "Mud and boulders on shoulder, one lane restricted."
        ),
        severity="Moderate",
        sampleLocation="Coastal Highway, Pier 12 Junction",
        latitude=18.9180,
        longitude=72.8450,
        timestamp=_iso(now - timedelta(hours=5)),
        status="Verified",
        syncStatus="synced",
        reporterEmail="citizen@lastsignal.demo",
        responderNotes="Heavy earth-moving excavator on site. Caution flags placed.",
        verifiedBy="Capt. Marcus Vance",
        isDraft=False,
    ),
    ReportCreate(
        id="REP-INF-04",
        hazardType="Damaged Infrastructure",
        description=(
            "Cracked expansion joint on South Pedestrian Overpass. "
            "Shaking under heavy pedestrian evacuation load."
        ),
        severity="High",
        sampleLocation="South Pedestrian Overpass, Rail Terminal",
        latitude=18.9240,
        longitude=72.8380,
        timestamp=_iso(now - timedelta(hours=9)),
        status="Resolved",
        syncStatus="synced",
        reporterEmail="citizen@lastsignal.demo",
        responderNotes="Structural engineers completed temporary shoring. Pedestrian flow stabilized.",
        verifiedBy="Capt. Marcus Vance",
        isDraft=False,
    ),
]


# ---------------------------------------------------------------------------
# Seed emergency locations  (mirrors mock_locations.dart)
# ---------------------------------------------------------------------------
SEED_LOCATIONS = [
    dict(
        id="LOC-HSP-01",
        name="Coastal General Hospital",
        type="hospital",
        sample_address="12 Medical Drive, Sector 2",
        distance_km=1.4,
        latitude=18.9350,
        longitude=72.8290,
        capacity=320,
        occupied=210,
        contact_phone="+1 (555) 200-1100",
        is_open=True,
        is_saved_offline=True,
        available_services=["Emergency Care", "Trauma Unit", "ICU", "Blood Bank"],
    ),
    dict(
        id="LOC-SHL-01",
        name="North Ridge Evacuation Shelter",
        type="shelter",
        sample_address="Ridge Community Center, North Ave",
        distance_km=2.1,
        latitude=18.9430,
        longitude=72.8200,
        capacity=500,
        occupied=312,
        contact_phone="+1 (555) 344-7700",
        is_open=True,
        is_saved_offline=True,
        available_services=["Beds", "Food & Water", "Medical Aid", "Pet Friendly"],
    ),
    dict(
        id="LOC-CMD-01",
        name="CERT-9 Field Command Post",
        type="commandPost",
        sample_address="Pier 7 Industrial Zone",
        distance_km=0.8,
        latitude=18.9260,
        longitude=72.8340,
        capacity=50,
        occupied=28,
        contact_phone="+1 (555) 911-0099",
        is_open=True,
        is_saved_offline=True,
        available_services=["Dispatch", "Communications", "Medical Triage", "Rescue Coordination"],
    ),
    dict(
        id="LOC-REL-01",
        name="Sector 4 Relief Distribution Center",
        type="reliefCenter",
        sample_address="City Hall Annex, Sector 4 Blvd",
        distance_km=3.5,
        latitude=18.9140,
        longitude=72.8480,
        capacity=1000,
        occupied=445,
        contact_phone="+1 (555) 600-2255",
        is_open=True,
        is_saved_offline=True,
        available_services=["Food Kits", "Water Supply", "Blankets", "Medication", "Charging Stations"],
    ),
    dict(
        id="LOC-SHL-02",
        name="Hillview Secondary Shelter",
        type="shelter",
        sample_address="Hillview Secondary School, Hillview Drive",
        distance_km=4.2,
        latitude=18.9410,
        longitude=72.8230,
        capacity=250,
        occupied=89,
        contact_phone="+1 (555) 412-8800",
        is_open=False,
        is_saved_offline=True,
        available_services=["Beds", "Food & Water"],
    ),
]


# ---------------------------------------------------------------------------
# Seed notifications
# ---------------------------------------------------------------------------
SEED_NOTIFICATIONS = [
    dict(
        id="NOTIF-001",
        user_email="citizen@lastsignal.demo",
        title="Risk Level: HIGH — Coastal Surge Alert",
        message="AI model has elevated risk to HIGH for your area. Storm surge inundation risk confirmed.",
        type="riskUpdate",
        timestamp=_iso(now - timedelta(minutes=30)),
        related_report_id=None,
    ),
    dict(
        id="NOTIF-002",
        user_email="citizen@lastsignal.demo",
        title="Hazard Report Verified!",
        message="Report REP-FLD-01 (Flood) has been officially verified by responders.",
        type="reportVerified",
        timestamp=_iso(now - timedelta(minutes=20)),
        related_report_id="REP-FLD-01",
    ),
    dict(
        id="NOTIF-003",
        user_email="citizen@lastsignal.demo",
        title="Emergency Pack Reminder",
        message="Your 72-hour emergency pack checklist is 60% complete. Please review before evacuation.",
        type="emergencyPackReminder",
        timestamp=_iso(now - timedelta(hours=1)),
        related_report_id=None,
    ),
]


# ---------------------------------------------------------------------------
# Main seeder
# ---------------------------------------------------------------------------
def seed(force: bool = False) -> None:
    conn = get_connection()

    if force:
        print("[seed] Clearing existing data (--force)...")
        conn.execute("DELETE FROM notifications")
        conn.execute("DELETE FROM emergency_locations")
        conn.execute("DELETE FROM hazard_reports")
        conn.execute("DELETE FROM users")
        conn.commit()
    else:
        # Check if already seeded
        existing = conn.execute("SELECT COUNT(*) FROM users").fetchone()[0]
        if existing > 0:
            print(f"[seed] Database already has {existing} user(s). Skipping seed.")
            print("[seed] Use seed(force=True) or pass --force to reseed.")
            return

    print("[seed] Seeding database...")

    # Users
    for u in SEED_USERS:
        try:
            user_model.create_user(
                conn,
                id=u["id"],
                name=u["name"],
                email=u["email"],
                password_hash=u["password"],
                role=u["role"],
                is_approved=u["is_approved"],
                is_enabled=u["is_enabled"],
                emergency_contact_name=u["emergency_contact_name"],
                emergency_contact_phone=u["emergency_contact_phone"],
                organization=u["organization"],
                created_at=u["created_at"],
            )
            print(f"  [user] {u['email']}")
        except Exception as e:
            print(f"  [user] SKIP {u['email']}: {e}")

    # Reports
    for r in SEED_REPORTS:
        try:
            report_model.insert_report(conn, r)
            print(f"  [report] {r.id}")
        except Exception as e:
            print(f"  [report] SKIP {r.id}: {e}")

    # Locations
    for loc in SEED_LOCATIONS:
        try:
            location_model.insert_location(conn, **loc)
            print(f"  [location] {loc['id']}")
        except Exception as e:
            print(f"  [location] SKIP {loc['id']}: {e}")

    # Notifications
    for n in SEED_NOTIFICATIONS:
        try:
            notif_model.insert_notification(conn, **n)
            print(f"  [notification] {n['id']}")
        except Exception as e:
            print(f"  [notification] SKIP {n['id']}: {e}")

    conn.commit()
    print("[seed] Done.")


if __name__ == "__main__":
    init_db()
    force = "--force" in sys.argv
    seed(force=force)
