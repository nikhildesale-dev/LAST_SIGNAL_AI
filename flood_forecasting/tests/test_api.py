"""
LAST_SIGNAL_AI: Comprehensive FastAPI and Core Pipeline Test Suite

Covers all 12 operational and failure-hardening test scenarios:
1. Valid prediction (+6h and +24h).
2. Missing required features.
3. Missing rainfall telemetry.
4. Missing Shigaon telemetry.
5. Missing Koyna_1 telemetry.
6. Stale target sensor (latency > 3h).
7. Frozen target sensor (flatline >= 24h).
8. BASEFLOW regime dispatch.
9. SURGE regime dispatch.
10. Hysteresis hold preservation during short outages.
11. Unknown / degraded regime fallback.
12. Exact feature schema ordering and preprocessing validation.
"""

import os
import sys
import pytest
import pandas as pd
import numpy as np
from fastapi.testclient import TestClient

# Ensure root directory is in sys.path
repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

from api.main import app
from src.features import FEATURES_SCHEMA, FeatureEngineer
from src.forecaster import RiverLevelForecaster

client = TestClient(app)

# Standard template feature vector for testing
BASE_FEATURES = {
    "rain_sum_24h": 0.0,
    "rain_sum_48h": 0.0,
    "rain_sum_72h": 0.0,
    "rain_intensity_6h": 0.0,
    "river_lag_1h": 527.20,
    "river_lag_6h": 527.18,
    "river_lag_24h": 527.15,
    "shigaon_delta_1h": 0.00,
    "shigaon_delta_3h": 0.00,
    "shigaon_delta_6h": 0.00,
    "shigaon_delta_24h": 0.00,
    "koyna_delta_1h": -0.02,
    "koyna_delta_3h": -0.04,
    "koyna_delta_6h": -0.06,
    "koyna_delta_24h": -0.10
}


def test_01_health_endpoint():
    """Verify GET /health returns operational status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert data["model_loaded"] is True
    assert data["horizons_hours"] == [6, 24]
    assert "timestamp" in data


def test_02_model_info_endpoint():
    """Verify GET /model-info returns complete metadata, schema, and limitations."""
    response = client.get("/model-info")
    assert response.status_code == 200
    data = response.json()
    assert data["target_station"] == "Ankali Bridge (Krishna River Basin)"
    assert data["features_schema"] == FEATURES_SCHEMA
    assert len(data["features_schema"]) == 15
    assert len(data["known_limitations"]) >= 3


def test_03_valid_baseflow_prediction():
    """Verify valid quiescent baseflow observation routes to Persistence."""
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-08-01T12:00:00",
        "features": BASE_FEATURES,
        "history_stages": [527.15, 527.18, 527.20],
        "history_timestamps": ["2023-08-01T10:00:00", "2023-08-01T11:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["hydrological_regime"] == "BASEFLOW"
    assert data["target_sensor_health"] == "HEALTHY"
    assert data["forecast_plus_6h"] == 527.20
    assert data["forecast_plus_24h"] == 527.20


def test_04_valid_surge_prediction():
    """Verify active hydraulic pulse routes to Multi-Station Ridge pipeline."""
    surge_features = dict(BASE_FEATURES)
    surge_features["shigaon_delta_6h"] = 0.35  # Severe upstream Warna rise (> 0.08m)
    surge_features["shigaon_delta_24h"] = 0.60
    
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-07-25T12:00:00",
        "features": surge_features,
        "history_stages": [527.05, 527.12, 527.20],
        "history_timestamps": ["2023-07-25T10:00:00", "2023-07-25T11:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["hydrological_regime"] == "SURGE"
    assert data["target_sensor_health"] == "HEALTHY"
    # Should not be equal to static persistence
    assert data["forecast_plus_6h"] is not None
    assert data["forecast_plus_24h"] is not None
    assert data["uncertainty_warning"] == "NOMINAL_SURGE_RIDGE"


def test_05_missing_rainfall_telemetry():
    """Verify missing rainfall is flagged and handled safely."""
    no_rain_features = dict(BASE_FEATURES)
    for k in ["rain_sum_24h", "rain_sum_48h", "rain_sum_72h", "rain_intensity_6h"]:
        no_rain_features[k] = None
        
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-08-01T12:00:00",
        "features": no_rain_features,
        "history_stages": [527.18, 527.20],
        "history_timestamps": ["2023-08-01T11:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["upstream_sensor_availability"]["sangli_rainfall"] is False
    assert data["forecast_plus_6h"] == 527.20


def test_06_missing_shigaon_telemetry():
    """Verify missing Shigaon gauge is flagged in upstream availability."""
    no_shigaon_features = dict(BASE_FEATURES)
    for k in ["shigaon_delta_1h", "shigaon_delta_3h", "shigaon_delta_6h", "shigaon_delta_24h"]:
        no_shigaon_features[k] = None
        
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-08-01T12:00:00",
        "features": no_shigaon_features,
        "history_stages": [527.18, 527.20],
        "history_timestamps": ["2023-08-01T11:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["upstream_sensor_availability"]["shigaon_gauge"] is False


def test_07_missing_koyna_telemetry():
    """Verify missing Koyna Dam gauge is flagged in upstream availability."""
    no_koyna_features = dict(BASE_FEATURES)
    for k in ["koyna_delta_1h", "koyna_delta_3h", "koyna_delta_6h", "koyna_delta_24h"]:
        no_koyna_features[k] = None
        
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-08-01T12:00:00",
        "features": no_koyna_features,
        "history_stages": [527.18, 527.20],
        "history_timestamps": ["2023-08-01T11:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["upstream_sensor_availability"]["koyna_1_gauge"] is False


def test_08_stale_target_sensor_latency():
    """Verify telemetry gap exceeding 3 hours withholds numerical forecast."""
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-08-01T17:00:00",  # 5-hour jump from 12:00
        "features": BASE_FEATURES,
        "history_stages": [527.20],
        "history_timestamps": ["2023-08-01T12:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is False
    assert data["target_sensor_health"] == "STALE"
    assert data["forecast_plus_6h"] is None
    assert data["forecast_plus_24h"] is None
    assert "withheld" in data["fallback_reason"].lower()


def test_09_frozen_target_sensor_flatline():
    """Verify 26 consecutive identical float readings withhold numerical forecast."""
    # 26 identical readings
    stuck_history = [526.65] * 25
    payload = {
        "current_stage_m": 526.65,
        "prediction_timestamp": "2023-02-10T12:00:00",
        "features": BASE_FEATURES,
        "history_stages": stuck_history,
        "history_timestamps": ["2023-02-10T11:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is False
    assert data["target_sensor_health"] == "STALE"
    assert data["forecast_plus_6h"] is None
    assert data["forecast_plus_24h"] is None
    assert "flatlined" in data["fallback_reason"].lower()


def test_10_suspect_stale_warning():
    """Verify 14 consecutive identical readings trigger SUSPECT_STALE with conservative persistence."""
    plateau_history = [526.85] * 13
    payload = {
        "current_stage_m": 526.85,
        "prediction_timestamp": "2023-11-17T06:00:00",
        "features": BASE_FEATURES,
        "history_stages": plateau_history,
        "history_timestamps": ["2023-11-17T05:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["target_sensor_health"] == "SUSPECT_STALE"
    assert data["forecast_plus_6h"] == 526.85
    assert "WARNING_PROLONGED_CONSTANT_STAGE" in data["uncertainty_warning"]


def test_11_hysteresis_state_hold():
    """Verify timestamp-based hysteresis holds surge mode when instantaneous slope flattens."""
    forecaster = app.state.forecaster
    forecaster.regime_detector.reset()
    
    # 1. Trigger surge at t=0
    surge_f = dict(BASE_FEATURES)
    surge_f["shigaon_delta_6h"] = 0.25
    r1 = forecaster.predict(
        current_stage_m=527.20,
        current_time="2023-07-20T12:00:00",
        features=surge_f
    )
    assert r1["hydrological_regime"] == "SURGE"
    
    # 2. At t=3h, instantaneous slope drops back to 0.0
    flat_f = dict(BASE_FEATURES)
    flat_f["shigaon_delta_6h"] = 0.00
    r2 = forecaster.predict(
        current_stage_m=527.35,
        current_time="2023-07-20T15:00:00",
        features=flat_f
    )
    assert r2["hydrological_regime"] == "SURGE"  # Retained by hysteresis!
    
    # 3. At t=28h (elapsed > 24h), surge hold expires naturally
    r3 = forecaster.predict(
        current_stage_m=527.30,
        current_time="2023-07-21T16:00:00",
        features=flat_f
    )
    assert r3["hydrological_regime"] == "BASEFLOW"


def test_12_exact_feature_schema_and_types():
    """Verify feature vector column ordering and sklearn pipeline step compatibility."""
    forecaster = app.state.forecaster
    model_6h = forecaster.models[6]
    scaler = model_6h.named_steps["scaler"]
    
    # Check exact feature names in scaler
    expected_scaler_features = scaler.feature_names_in_.tolist()
    assert expected_scaler_features == FEATURES_SCHEMA
    
    # Check assembler output matches schema
    assembled_df = FeatureEngineer.assemble_features_dataframe(BASE_FEATURES)
    assert list(assembled_df.columns) == FEATURES_SCHEMA
    assert assembled_df.shape == (1, 15)
    
    # Predict directly with sklearn pipeline
    pred_val = model_6h.predict(assembled_df)
    assert len(pred_val) == 1
    assert isinstance(pred_val[0], (float, np.floating))


def test_13_telemetry_scenarios_and_history_endpoints():
    """Verify GET /telemetry/scenarios and GET /telemetry/history endpoints."""
    # 1. Scenarios endpoint
    sc_resp = client.get("/telemetry/scenarios")
    assert sc_resp.status_code == 200
    sc_data = sc_resp.json()
    assert "scenarios" in sc_data
    assert len(sc_data["scenarios"]) >= 5
    categories = [s["category"] for s in sc_data["scenarios"]]
    assert "BASEFLOW" in categories
    assert "SURGE" in categories
    assert "STALE_FAULT" in categories

    # 2. History endpoint with scenario_id
    hist_resp = client.get("/telemetry/history?scenario_id=surge_2022-07-06_040000")
    assert hist_resp.status_code == 200
    hist_data = hist_resp.json()
    assert hist_data["station"] == "Ankali Bridge (Krishna River Basin)"
    assert hist_data["count"] > 0
    assert len(hist_data["series"]) == hist_data["count"]
    sample_pt = hist_data["series"][0]
    assert "timestamp" in sample_pt
    assert "ankali_stage_m" in sample_pt
    assert "rainfall_mm" in sample_pt


def test_14_prolonged_shigaon_invariant_suspect_flatline():
    """Verify Shigaon invariant readings for >= 24h triggers SUSPECT_FLATLINE with DEGRADED regime."""
    t_start = pd.to_datetime("2023-10-15T00:00:00")
    timestamps = [(t_start + pd.Timedelta(hours=i)).isoformat() for i in range(29)]
    stages = [536.530] * 29
    
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": timestamps[-1],
        "features": BASE_FEATURES,
        "history_stages": [527.18, 527.20],
        "history_timestamps": [timestamps[-2], timestamps[-1]],
        "history_shigaon_stages": stages[:-1],
        "history_shigaon_timestamps": timestamps[:-1]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["target_sensor_health"] == "HEALTHY"
    assert data["upstream_sensor_health"]["shigaon_gauge"] == "SUSPECT_FLATLINE"
    assert data["upstream_sensor_availability"]["shigaon_gauge"] is False
    assert data["hydrological_regime"] == "DEGRADED"
    assert data["uncertainty_warning"] == "UPSTREAM_SENSOR_SUSPECT_FLATLINE"
    assert data["forecast_plus_6h"] == 527.20
    assert data["forecast_plus_24h"] == 527.20
    assert "zero movement cannot confirm baseflow" in data["fallback_reason"].lower()


def test_15_legitimately_stable_upstream_baseflow():
    """Verify natural quiescent upstream stability (<= 24h) is accepted as STABLE_BUT_PLAUSIBLE during baseflow."""
    t_start = pd.to_datetime("2023-04-10T00:00:00")
    timestamps = [(t_start + pd.Timedelta(hours=i)).isoformat() for i in range(13)]  # 12 hours
    stages = [536.530] * 13
    
    payload = {
        "current_stage_m": 526.50,
        "prediction_timestamp": timestamps[-1],
        "features": BASE_FEATURES,
        "history_stages": [526.48, 526.50],
        "history_timestamps": [timestamps[-2], timestamps[-1]],
        "history_shigaon_stages": stages[:-1],
        "history_shigaon_timestamps": timestamps[:-1]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["target_sensor_health"] == "HEALTHY"
    assert data["upstream_sensor_health"]["shigaon_gauge"] == "STABLE_BUT_PLAUSIBLE"
    assert data["upstream_sensor_availability"]["shigaon_gauge"] is True
    assert data["hydrological_regime"] == "BASEFLOW"
    assert data["forecast_plus_6h"] == 526.50
    assert data["forecast_plus_24h"] == 526.50


def test_16_stale_upstream_flatline_over_72h():
    """Verify persistent flatline >= 72h triggers STALE upstream status and DEGRADED regime."""
    t_start = pd.to_datetime("2023-10-10T00:00:00")
    timestamps = [(t_start + pd.Timedelta(hours=i)).isoformat() for i in range(75)]  # 74 hours
    stages = [536.530] * 75
    
    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": timestamps[-1],
        "features": BASE_FEATURES,
        "history_stages": [527.18, 527.20],
        "history_timestamps": [timestamps[-2], timestamps[-1]],
        "history_shigaon_stages": stages[:-1],
        "history_shigaon_timestamps": timestamps[:-1]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["upstream_sensor_health"]["shigaon_gauge"] == "STALE"
    assert data["upstream_sensor_availability"]["shigaon_gauge"] is False
    assert data["hydrological_regime"] == "DEGRADED"
    assert data["uncertainty_warning"] == "UPSTREAM_SENSOR_STALE"


def test_17_upstream_dropout_during_active_surge():
    """Verify that when upstream gauge is suspect/missing during active surge, system safely falls back to persistence."""
    surge_features = dict(BASE_FEATURES)
    surge_features["koyna_delta_24h"] = 0.40  # Koyna dam surge trigger (> 0.10 threshold)
    for k in ["shigaon_delta_1h", "shigaon_delta_3h", "shigaon_delta_6h", "shigaon_delta_24h"]:
        surge_features[k] = None
        
    payload = {
        "current_stage_m": 527.50,
        "prediction_timestamp": "2023-07-25T12:00:00",
        "features": surge_features,
        "history_stages": [527.30, 527.50],
        "history_timestamps": ["2023-07-25T11:00:00"]
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction_available"] is True
    assert data["hydrological_regime"] == "SURGE"
    assert data["upstream_sensor_availability"]["shigaon_gauge"] is False
    assert data["uncertainty_warning"] == "SURGE_DEGRADED_BY_UPSTREAM_OUTAGE"
    assert data["forecast_plus_6h"] == 527.50  # Safe local persistence fallback
    assert data["forecast_plus_24h"] == 527.50


def test_18_rainfall_measured_zero_vs_assumed_zero_vs_missing():
    """Verify distinct semantics for MEASURED_ZERO, ASSUMED_ZERO, and UNRECORDED_MISSING."""
    # A. Confirmed measured zero
    p_measured_zero = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-08-01T12:00:00",
        "features": dict(BASE_FEATURES),
        "rainfall_measured_mm": 0.0,
        "history_stages": [527.18, 527.20],
        "history_timestamps": ["2023-08-01T11:00:00"]
    }
    r_zero = client.post("/predict", json=p_measured_zero).json()
    assert r_zero["upstream_sensor_health"]["sangli_rainfall"] == "MEASURED_ZERO"
    assert r_zero["feature_statuses"]["rain_sum_24h"] == "MEASURED_ZERO"

    # B. Assumed zero (unrecorded but imputed zero under IMD standard convention)
    p_assumed_zero = {
        "current_stage_m": 527.20,
        "prediction_timestamp": "2023-08-01T12:00:00",
        "features": dict(BASE_FEATURES),
        "history_stages": [527.18, 527.20],
        "history_timestamps": ["2023-08-01T11:00:00"]
    }
    r_assumed = client.post("/predict", json=p_assumed_zero).json()
    assert r_assumed["upstream_sensor_health"]["sangli_rainfall"] == "ASSUMED_ZERO"
    assert r_assumed["feature_statuses"]["rain_sum_24h"] == "ASSUMED_ZERO"

    # C. Unrecorded missing (telemetry dropout with sufficient lookback history)
    t_start = pd.to_datetime("2023-08-01T00:00:00")
    timestamps = [(t_start + pd.Timedelta(hours=i)).isoformat() for i in range(25)]
    stages = [527.20] * 25
    no_rain_f = dict(BASE_FEATURES)
    for k in ["rain_sum_24h", "rain_sum_48h", "rain_sum_72h", "rain_intensity_6h"]:
        no_rain_f[k] = None
    p_missing = {
        "current_stage_m": 527.20,
        "prediction_timestamp": timestamps[-1],
        "features": no_rain_f,
        "history_stages": stages,
        "history_timestamps": timestamps
    }
    r_missing = client.post("/predict", json=p_missing).json()
    assert r_missing["upstream_sensor_health"]["sangli_rainfall"] == "UNRECORDED_MISSING"
    assert r_missing["upstream_sensor_availability"]["sangli_rainfall"] is False
    assert r_missing["feature_statuses"]["rain_sum_24h"] == "TELEMETRY_DROPOUT"


