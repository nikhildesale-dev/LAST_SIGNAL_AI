"""schemas/location.py — Pydantic models for emergency_locations."""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, ConfigDict


class LocationOut(BaseModel):
    """Matches EmergencyLocation.fromJson() field names."""
    model_config = ConfigDict(populate_by_name=True)

    id: str
    name: str
    type: str
    sampleAddress: str
    distanceKm: float
    latitude: float
    longitude: float
    capacity: int
    occupied: int
    contactPhone: str
    isOpen: bool
    isSavedOffline: bool
    availableServices: list[str]
