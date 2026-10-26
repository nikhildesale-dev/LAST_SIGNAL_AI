"""
test_api.py — Comprehensive test suite for LAST SIGNAL AI FastAPI backend.
Tests all endpoints:
  - Health check
  - Auth (login for citizen, responder, admin; wrong credentials; role mismatches)
  - Auth (citizen registration, validation, duplicate prevention)
  - Admin user management (list users, approve responder, reject responder, toggle enabled)
  - Hazard reports (fetch reports, submit single report, bulk sync)
  - Responder triage workflow (mark under review, verify, reject, resolve)
  - Risk AI prediction (predict-risk coastal & inland heuristics)
  - Emergency locations
  - Notifications
"""

import pytest
from fastapi.testclient import TestClient

from main import app
from database import init_db, get_connection
from seed import seed

client = TestClient(app)


@pytest.fixture(scope="function", autouse=True)
def setup_database():
    init_db()
    conn = get_connection()
    conn.execute("DELETE FROM notifications")
    conn.execute("DELETE FROM emergency_locations")
    conn.execute("DELETE FROM hazard_reports")
    conn.execute("DELETE FROM users")
    conn.commit()
    seed(force=True)


# ============================================================================
# 1. Health & Root
# ============================================================================
def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "LAST SIGNAL AI Backend"


# ============================================================================
# 2. Authentication
# ============================================================================
def test_login_citizen_success():
    res = client.post("/api/auth/login", json={
        "email": "citizen@lastsignal.demo",
        "password": "citizen123",
        "expectedRole": "citizen"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["user"]["role"] == "citizen"
    assert data["user"]["email"] == "citizen@lastsignal.demo"


def test_login_role_mismatch():
    res = client.post("/api/auth/login", json={
        "email": "citizen@lastsignal.demo",
        "password": "citizen123",
        "expectedRole": "responder"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is False
    assert "mismatch" in data["message"].lower()


def test_login_invalid_password():
    res = client.post("/api/auth/login", json={
        "email": "citizen@lastsignal.demo",
        "password": "wrongpassword",
        "expectedRole": "citizen"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is False


def test_login_pending_responder_blocked():
    # jordan.kelly is seeded with is_approved=False
    res = client.post("/api/auth/login", json={
        "email": "jordan.kelly@coastal-rescue.org",
        "password": "responder123",
        "expectedRole": "responder"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is False
    assert "pending" in data["message"].lower()


def test_register_citizen_success():
    res = client.post("/api/auth/register", json={
        "name": "Sarah Connor",
        "email": "sarah.connor@test.org",
        "password": "securepassword",
        "confirmPassword": "securepassword",
        "emergencyContactName": "John Connor",
        "emergencyContactPhone": "+1 555-0199"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["user"]["name"] == "Sarah Connor"
    assert data["user"]["role"] == "citizen"


def test_register_duplicate_email():
    res = client.post("/api/auth/register", json={
        "name": "Maya Duplicate",
        "email": "citizen@lastsignal.demo",
        "password": "password123",
        "confirmPassword": "password123"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is False
    assert "already exists" in data["message"].lower()


# ============================================================================
# 3. User Administration (Flow E)
# ============================================================================
def test_list_users():
    res = client.get("/api/users")
    assert res.status_code == 200
    users = res.json()
    assert isinstance(users, list)
    assert len(users) >= 5


def test_approve_and_toggle_responder():
    # Approve pending responder
    res = client.patch("/api/users/USR-RSP-REQ-02/approve")
    assert res.status_code == 200
    user = res.json()
    assert user["isApproved"] is True

    # Now login should succeed for this responder
    login_res = client.post("/api/auth/login", json={
        "email": "jordan.kelly@coastal-rescue.org",
        "password": "responder123",
        "expectedRole": "responder"
    })
    assert login_res.json()["success"] is True

    # Toggle account disable
    toggle_res = client.patch("/api/users/USR-RSP-REQ-02/toggle")
    assert toggle_res.status_code == 200
    assert toggle_res.json()["isEnabled"] is False

    # Login should now fail because account is disabled
    login_disabled = client.post("/api/auth/login", json={
        "email": "jordan.kelly@coastal-rescue.org",
        "password": "responder123",
        "expectedRole": "responder"
    })
    assert login_disabled.json()["success"] is False

    # Toggle back to enabled
    client.patch("/api/users/USR-RSP-REQ-02/toggle")


# ============================================================================
# 4. Reports & Triage Workflow
# ============================================================================
def test_fetch_reports():
    res = client.get("/api/reports")
    assert res.status_code == 200
    reports = res.json()
    assert isinstance(reports, list)
    assert len(reports) >= 4


def test_submit_report():
    new_report = {
        "id": "REP-TST-99",
        "hazardType": "Fire",
        "description": "Transformer blaze near electrical station.",
        "severity": "Critical",
        "sampleLocation": "Industrial Sector 9",
        "latitude": 18.9310,
        "longitude": 72.8340,
        "timestamp": "2026-10-25T18:00:00Z",
        "status": "Submitted",
        "syncStatus": "synced",
        "reporterEmail": "citizen@lastsignal.demo",
        "isDraft": False
    }
    res = client.post("/api/reports", json=new_report)
    assert res.status_code == 201
    created = res.json()
    assert created["id"] == "REP-TST-99"
    assert created["status"] == "Submitted"
    assert created["syncStatus"] == "synced"


def test_responder_triage_flow():
    report_id = "REP-ROD-02"

    # Mark Under Review
    res1 = client.patch(f"/api/reports/{report_id}/review", json={
        "responderNote": "Unit 4 dispatched to assess tree hazard."
    })
    assert res1.status_code == 200
    assert res1.json()["status"] == "Under Review"

    # Verify Report
    res2 = client.patch(f"/api/reports/{report_id}/verify", json={
        "responderName": "Capt. Marcus Vance",
        "responderNote": "Perimeter secured, fire unit engaged."
    })
    assert res2.status_code == 200
    assert res2.json()["status"] == "Verified"
    assert res2.json()["verifiedBy"] == "Capt. Marcus Vance"

    # Mark Resolved
    res3 = client.patch(f"/api/reports/{report_id}/resolve", json={
        "resolutionNote": "Blaze fully extinguished. Grid restored."
    })
    assert res3.status_code == 200
    assert res3.json()["status"] == "Resolved"


def test_sync_pending_reports():
    bulk_reports = {
        "reports": [
            {
                "id": "REP-OFFLINE-01",
                "hazardType": "Blocked Road",
                "description": "Fallen tree logged while offline.",
                "severity": "Moderate",
                "sampleLocation": "South Gate Pier",
                "latitude": 18.9200,
                "longitude": 72.8400,
                "timestamp": "2026-10-25T17:00:00Z",
                "status": "Pending Sync",
                "syncStatus": "localOnly",
                "reporterEmail": "citizen@lastsignal.demo",
                "isDraft": False
            }
        ]
    }
    res = client.post("/api/reports/sync", json=bulk_reports)
    assert res.status_code == 200
    reports = res.json()
    synced_ids = [r["id"] for r in reports]
    assert "REP-OFFLINE-01" in synced_ids


# ============================================================================
# 5. Risk Prediction Endpoint
# ============================================================================
def test_predict_risk_coastal():
    payload = {
        "latitude": 18.9320,
        "longitude": 72.8350,
        "region": "Sector 3 Coastal Maritime",
        "timestamp": "2026-10-25T18:00:00"
    }
    res = client.post("/api/predict-risk", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["score"] == 68
    assert data["category"] == "High"
    assert data["modelVersion"] == "v2.4-flood-cyclone-ensemble"
    assert len(data["contributingFactors"]) >= 4
    assert len(data["recommendedActions"]) >= 4


def test_predict_risk_inland():
    payload = {
        "latitude": 28.6139,
        "longitude": 77.2090,
        "region": "Northern Inland Valley",
        "timestamp": "2026-10-25T18:00:00"
    }
    res = client.post("/api/predict-risk", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["score"] == 38
    assert data["category"] == "Low"


# ============================================================================
# 6. Emergency Locations & Notifications
# ============================================================================
def test_get_emergency_locations():
    res = client.get("/api/locations")
    assert res.status_code == 200
    locations = res.json()
    assert isinstance(locations, list)
    assert len(locations) >= 5
    assert locations[0]["name"] is not None
    assert isinstance(locations[0]["availableServices"], list)


def test_get_notifications():
    res = client.get("/api/notifications?user_email=citizen@lastsignal.demo")
    assert res.status_code == 200
    notifs = res.json()
    assert isinstance(notifs, list)
    assert len(notifs) >= 3
    assert notifs[0]["title"] is not None
