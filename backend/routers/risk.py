"""routers/risk.py — POST /api/predict-risk"""

from __future__ import annotations

from fastapi import APIRouter

from schemas.risk import RiskPredictRequest, RiskPredictResponse
from services.risk_engine import predict_area_risk

router = APIRouter(prefix="/api", tags=["risk"])


@router.post("/predict-risk", response_model=RiskPredictResponse)
def predict_risk(body: RiskPredictRequest):
    """
    Called by ApiService.predictDisasterRisk().
    Returns a RiskPredictResponse whose field names exactly match what
    the Flutter code reads from the JSON body.
    """
    return predict_area_risk(
        latitude=body.latitude,
        longitude=body.longitude,
        region=body.region or "Unknown Region",
    )
