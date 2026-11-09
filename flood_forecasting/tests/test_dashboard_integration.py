"""
LAST_SIGNAL_AI: Dashboard End-to-End API Integration Test Suite

Verifies:
1. Health & Model-info contracts consumed by Header and Details panels.
2. Scenarios list contracts consumed by ScenarioSelector.
3. Telemetry history contracts consumed by ForecastChart and UpstreamMonitoringPanel.
4. Predict contracts consumed by OverviewCards and SensorHealthPanel across:
   - Healthy Baseflow
   - Healthy Surge (Ridge)
   - Stale Sensor Fault (Forecasts Withheld)
   - River Plateau (SUSPECT_STALE)
   - Upstream Gauge Dropout
"""

import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure root directory in python path
repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

from api.main import app

client = TestClient(app)


def test_dashboard_01_health_and_metadata():
    """Verify Header and Footer metadata contracts."""
    health_resp = client.get("/health")
    assert health_resp.status_code == 200
    h_data = health_resp.json()
    assert h_data["status"] == "HEALTHY"
    assert h_data["model_loaded"] is True
    assert h_data["horizons_hours"] == [6, 24]

    info_resp = client.get("/model-info")
    assert info_resp.status_code == 200
    info_data = info_resp.json()
    assert "Ankali Bridge" in info_data["target_station"]
    assert len(info_data["upstream_stations"]) == 2
    assert len(info_data["features_schema"]) == 15
    assert len(info_data["known_limitations"]) >= 3


def test_dashboard_02_scenarios_listing():
    """Verify ScenarioSelector episodes availability."""
    sc_resp = client.get("/telemetry/scenarios")
    assert sc_resp.status_code == 200
    sc_data = sc_resp.json()
    assert "scenarios" in sc_data
    scenarios = sc_data["scenarios"]
    assert len(scenarios) >= 5

    categories = {s["category"]: s for s in scenarios}
    assert "BASEFLOW" in categories
    assert "SURGE" in categories
    assert "STALE_FAULT" in categories
    assert "PLATEAU_WARNING" in categories
    assert "DROPOUT" in categories

    # Verify each scenario carries required prediction payload
    for sc in scenarios:
        assert "prediction_timestamp" in sc
        assert "features" in sc
        assert len(sc["features"]) == 15


def test_dashboard_03_telemetry_history_no_invented_data():
    """Verify telemetry history preserves authentic un-interpolated missing values."""
    hist_resp = client.get("/telemetry/history?limit=168")
    assert hist_resp.status_code == 200
    hist_data = hist_resp.json()
    assert hist_data["count"] > 0
    assert len(hist_data["series"]) == hist_data["count"]

    # Check structure
    sample = hist_data["series"][0]
    assert "timestamp" in sample
    assert "ankali_stage_m" in sample
    assert "shigaon_stage_m" in sample
    assert "koyna_stage_m" in sample
    assert "rainfall_mm" in sample
    assert "ankali_avail" in sample

    # Ensure missing readings are returned as None (JSON null), never invented/zero-filled
    has_null = any(pt["ankali_stage_m"] is None or pt["shigaon_stage_m"] is None for pt in hist_data["series"])
    assert has_null, "Real telemetry must reflect actual station dropouts as null"


def test_dashboard_04_surge_regime_prediction():
    """Verify surge scenario triggers Multi-Station Ridge with valid forecasts."""
    sc_resp = client.get("/telemetry/scenarios")
    scenarios = sc_resp.json()["scenarios"]
    surge_sc = next(s for s in scenarios if s["category"] == "SURGE")

    pred_resp = client.post("/predict", json={
        "current_stage_m": surge_sc["current_stage_m"],
        "prediction_timestamp": surge_sc["prediction_timestamp"],
        "features": surge_sc["features"],
        "history_stages": surge_sc["history_stages"],
        "history_timestamps": surge_sc["history_timestamps"]
    })
    assert pred_resp.status_code == 200
    data = pred_resp.json()
    assert data["prediction_available"] is True
    assert data["hydrological_regime"] == "SURGE"
    assert data["target_sensor_health"] == "HEALTHY"
    assert data["forecast_plus_6h"] is not None
    assert data["forecast_plus_24h"] is not None


def test_dashboard_05_stale_sensor_withholding():
    """Verify stuck sensor flatline suppresses numerical forecast."""
    sc_resp = client.get("/telemetry/scenarios")
    scenarios = sc_resp.json()["scenarios"]
    stale_sc = next(s for s in scenarios if s["category"] == "STALE_FAULT")

    pred_resp = client.post("/predict", json={
        "current_stage_m": stale_sc["current_stage_m"],
        "prediction_timestamp": stale_sc["prediction_timestamp"],
        "features": stale_sc["features"],
        "history_stages": stale_sc["history_stages"],
        "history_timestamps": stale_sc["history_timestamps"]
    })
    assert pred_resp.status_code == 200
    data = pred_resp.json()
    assert data["prediction_available"] is False
    assert data["target_sensor_health"] == "STALE"
    assert data["forecast_plus_6h"] is None
    assert data["forecast_plus_24h"] is None
    assert data["fallback_reason"] is not None


def test_dashboard_06_plateau_suspect_stale_warning():
    """Verify 13h stable stage triggers SUSPECT_STALE with persistence forecast."""
    sc_resp = client.get("/telemetry/scenarios")
    scenarios = sc_resp.json()["scenarios"]
    plateau_sc = next(s for s in scenarios if s["category"] == "PLATEAU_WARNING")

    pred_resp = client.post("/predict", json={
        "current_stage_m": plateau_sc["current_stage_m"],
        "prediction_timestamp": plateau_sc["prediction_timestamp"],
        "features": plateau_sc["features"],
        "history_stages": plateau_sc["history_stages"],
        "history_timestamps": plateau_sc["history_timestamps"]
    })
    assert pred_resp.status_code == 200
    data = pred_resp.json()
    assert data["prediction_available"] is True
    assert data["target_sensor_health"] == "SUSPECT_STALE"
    assert data["hydrological_regime"] == "BASEFLOW"
    assert data["forecast_plus_6h"] == plateau_sc["current_stage_m"]


def test_dashboard_07_upstream_dropout_handling():
    """Verify upstream telemetry dropout flags outage and provides safe persistence."""
    sc_resp = client.get("/telemetry/scenarios")
    scenarios = sc_resp.json()["scenarios"]
    dropout_sc = next(s for s in scenarios if s["category"] == "DROPOUT")

    pred_resp = client.post("/predict", json={
        "current_stage_m": dropout_sc["current_stage_m"],
        "prediction_timestamp": dropout_sc["prediction_timestamp"],
        "features": dropout_sc["features"],
        "history_stages": dropout_sc["history_stages"],
        "history_timestamps": dropout_sc["history_timestamps"]
    })
    assert pred_resp.status_code == 200
    data = pred_resp.json()
    assert data["upstream_sensor_availability"]["shigaon_gauge"] is False
    assert data["prediction_available"] is True
    assert data["hydrological_regime"] == "BASEFLOW"
    assert data["target_sensor_health"] == "HEALTHY"
    assert data["uncertainty_warning"] == "UPSTREAM_TELEMETRY_DEGRADED"
    assert "feature_statuses" in data
    assert data["feature_statuses"]["shigaon_delta_1h"] == "TELEMETRY_DROPOUT"
    assert data["feature_statuses"]["river_lag_6h"] == "INSUFFICIENT_HISTORY"
    assert data["feature_statuses"]["koyna_delta_1h"] == "OK"
    assert data["feature_statuses"]["koyna_delta_6h"] == "INSUFFICIENT_HISTORY"
    assert data["feature_statuses"]["rain_sum_24h"] == "INSUFFICIENT_HISTORY"


def test_dashboard_08_upstream_suspect_flatline_dashboard_contract():
    """Verify that when Shigaon has suspect flatline, dashboard receives separated target and upstream status."""
    import pandas as pd
    t_start = pd.to_datetime("2023-10-15T00:00:00")
    timestamps = [(t_start + pd.Timedelta(hours=i)).isoformat() for i in range(29)]
    stages = [536.530] * 29

    payload = {
        "current_stage_m": 527.20,
        "prediction_timestamp": timestamps[-1],
        "features": {
            "rain_sum_24h": 0.0, "rain_sum_48h": 0.0, "rain_sum_72h": 0.0, "rain_intensity_6h": 0.0,
            "river_lag_1h": 527.20, "river_lag_6h": 527.18, "river_lag_24h": 527.15,
            "shigaon_delta_1h": 0.00, "shigaon_delta_3h": 0.00, "shigaon_delta_6h": 0.00, "shigaon_delta_24h": 0.00,
            "koyna_delta_1h": -0.02, "koyna_delta_3h": -0.04, "koyna_delta_6h": -0.06, "koyna_delta_24h": -0.10
        },
        "history_stages": [527.18, 527.20],
        "history_timestamps": [timestamps[-2], timestamps[-1]],
        "history_shigaon_stages": stages[:-1],
        "history_shigaon_timestamps": timestamps[:-1]
    }
    pred_resp = client.post("/predict", json=payload)
    assert pred_resp.status_code == 200
    data = pred_resp.json()
    assert data["target_sensor_health"] == "HEALTHY"
    assert data["upstream_sensor_health"]["shigaon_gauge"] == "SUSPECT_FLATLINE"
    assert data["hydrological_regime"] == "DEGRADED"
    assert data["uncertainty_warning"] == "UPSTREAM_SENSOR_SUSPECT_FLATLINE"
    assert "cannot confirm baseflow" in data["fallback_reason"].lower()


def test_dashboard_09_all_historical_scenarios_execute_with_upstream_health():
    """Verify all 5 historical scenarios execute reliably and contain upstream health diagnostics."""
    sc_resp = client.get("/telemetry/scenarios")
    assert sc_resp.status_code == 200
    scenarios = sc_resp.json()["scenarios"]
    assert len(scenarios) >= 5

    for sc in scenarios:
        payload = {
            "current_stage_m": sc["current_stage_m"],
            "prediction_timestamp": sc["prediction_timestamp"],
            "features": sc["features"],
            "history_stages": sc["history_stages"],
            "history_timestamps": sc["history_timestamps"],
            "history_shigaon_stages": sc.get("history_shigaon_stages"),
            "history_shigaon_timestamps": sc.get("history_shigaon_timestamps"),
            "history_koyna_stages": sc.get("history_koyna_stages"),
            "history_koyna_timestamps": sc.get("history_koyna_timestamps")
        }
        res = client.post("/predict", json=payload)
        assert res.status_code == 200
        d = res.json()
        assert "target_sensor_health" in d
        assert "upstream_sensor_health" in d
        assert "shigaon_gauge" in d["upstream_sensor_health"]
        assert "koyna_1_gauge" in d["upstream_sensor_health"]
        assert "sangli_rainfall" in d["upstream_sensor_health"]
        
        # Verify Ankali flatline behavior preserved in STALE_FAULT
        if sc["category"] == "STALE_FAULT":
            assert d["prediction_available"] is False
            assert d["target_sensor_health"] == "STALE"
            assert d["forecast_plus_6h"] is None
            assert d["forecast_plus_24h"] is None


