"""routers/locations.py — GET /api/locations"""

from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends

from database import get_db
from models import location as location_model
from schemas.location import LocationOut

router = APIRouter(prefix="/api", tags=["locations"])


@router.get("/locations", response_model=list[LocationOut])
def get_locations(conn: sqlite3.Connection = Depends(get_db)):
    """
    Return all emergency locations (shelters, hospitals, command posts, etc.).
    Used by InteractiveMapScreen to display markers.
    """
    return location_model.get_all_locations(conn)
