"""models/location.py — Raw sqlite3 CRUD helpers for emergency_locations."""

from __future__ import annotations

import json
import sqlite3

from schemas.location import LocationOut


def _row_to_location_out(row: sqlite3.Row) -> LocationOut:
    services = row["available_services"]
    if isinstance(services, str):
        try:
            services = json.loads(services)
        except Exception:
            services = []

    return LocationOut(
        id=row["id"],
        name=row["name"],
        type=row["type"],
        sampleAddress=row["sample_address"],
        distanceKm=row["distance_km"],
        latitude=row["latitude"],
        longitude=row["longitude"],
        capacity=row["capacity"],
        occupied=row["occupied"],
        contactPhone=row["contact_phone"],
        isOpen=bool(row["is_open"]),
        isSavedOffline=bool(row["is_saved_offline"]),
        availableServices=services,
    )


def get_all_locations(conn: sqlite3.Connection) -> list[LocationOut]:
    rows = conn.execute(
        "SELECT * FROM emergency_locations ORDER BY distance_km ASC"
    ).fetchall()
    return [_row_to_location_out(r) for r in rows]


def insert_location(conn: sqlite3.Connection, *, id: str, name: str, type: str,
                    sample_address: str, distance_km: float, latitude: float,
                    longitude: float, capacity: int, occupied: int,
                    contact_phone: str, is_open: bool, is_saved_offline: bool,
                    available_services: list) -> None:
    conn.execute(
        """
        INSERT OR IGNORE INTO emergency_locations
            (id, name, type, sample_address, distance_km, latitude, longitude,
             capacity, occupied, contact_phone, is_open, is_saved_offline, available_services)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (id, name, type, sample_address, distance_km, latitude, longitude,
         capacity, occupied, contact_phone, int(is_open), int(is_saved_offline),
         json.dumps(available_services)),
    )
