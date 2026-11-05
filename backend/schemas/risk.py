"""schemas/risk.py — Pydantic models for the AI risk prediction endpoint."""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel


class RiskPredictRequest(BaseModel):
    """Matches the payload built in ApiService.predictDisasterRisk()."""
    latitude: float
    longitude: float
    region: Optional[str] = "Unknown Region"
    timestamp: Optional[str] = None


class RiskFactor(BaseModel):
    """Matches Flutter RiskFactor fields read in ApiService."""
    name: str
    weight: float
    status: str
    details: str


class RiskPredictResponse(BaseModel):
    """
    Field names match exactly what Flutter's ApiService.predictDisasterRisk()
    reads from the JSON body:
        data['score'], data['category'], data['modelVersion'],
        data['confidenceScore'], data['summary'],
        data['contributingFactors'], data['recommendedActions']
    """
    score: int
    category: str
    modelVersion: str
    confidenceScore: float
    summary: str
    contributingFactors: list[RiskFactor]
    recommendedActions: list[str]
