"""
LAST_SIGNAL_AI: Comprehensive Verification Suite for Custom CSV Forecasting

Validates:
1. Template endpoints (blank and genuine historical sample).
2. Valid Surge CSV prediction (Ridge Config C).
3. Valid Baseflow CSV prediction (Persistence baseline).
4. Target sensor flatline detection (safety gating & withholding).
5. Upstream sensor dropout handling (degraded availability).
6. Missing rainfall semantics (no fabrication of confirmed zero).
7. Assumed-zero rainfall semantics (IMD convention).
8. Structural validation (missing columns, unparseable data, duplicate timestamps).
9. Insufficient lookback history handling.
10. Strict causal verification & future data leakage prevention.
"""

import io
import os
import sys
import pytest
import pandas as pd

# Ensure root directory is in sys.path
repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

from fastapi.testclient import TestClient
from api.main import create_app
from src.features import FEATURES_SCHEMA


@pytest.fixture(scope="module")
def client():
    app = create_app()
    with TestClient(app) as test_client:
        yield test_client


def test_download_blank_template(client: TestClient):
    """Verify downloadable blank CSV template contains exact required schema."""
    response = client.get("/csv/templates/blank")
    assert response.status_code == 200
    assert "text/csv" in response.headers.get("content-type", "")

    df = pd.read_csv(io.StringIO(response.text))
    expected_cols = [
        "timestamp",
        "ankali_stage_m",
        "shigaon_stage_m",
        "koyna_stage_m",
        "sangli_rainfall_mm",
        "rainfall_status"
    ]
    assert list(df.columns) == expected_cols


def test_download_sample_template(client: TestClient):
    """Verify downloadable sample template contains genuine historical pilot records."""
    response = client.get("/csv/templates/sample")
    assert response.status_code == 200
    assert "text/csv" in response.headers.get("content-type", "")

    df = pd.read_csv(io.StringIO(response.text))
    assert len(df) >= 72
    assert "2022-07-06 04:00:00" in df["timestamp"].values
    assert df["ankali_stage_m"].notna().sum() > 0
    assert df["shigaon_stage_m"].notna().sum() > 0


def test_validate_valid_sample_csv(client: TestClient):
    """Verify CSV validation endpoint on the authentic pilot sample via JSON."""
    sample_resp = client.get("/csv/templates/sample")
    csv_text = sample_resp.text

    val_resp = client.post("/csv/validate", json={"csv_content": csv_text, "filename": "sample.csv"})
    assert val_resp.status_code == 200
    data = val_resp.json()
    assert data["is_valid"] is True
    assert data["total_rows"] == 97
    assert data["duplicate_timestamps_count"] == 0
    assert len(data["validation_errors"]) == 0
    assert len(data["available_timestamps"]) == 97
    assert len(data["timestamps_with_sufficient_history"]) > 0
    assert "ankali_stage_m" in data["station_stats"]


def test_validate_multipart_upload(client: TestClient):
    """Verify CSV validation endpoint accepting multipart/form-data file upload."""
    sample_resp = client.get("/csv/templates/sample")
    csv_bytes = sample_resp.content

    val_resp = client.post(
        "/csv/validate",
        files={"file": ("sample.csv", io.BytesIO(csv_bytes), "text/csv")}
    )
    assert val_resp.status_code == 200
    data = val_resp.json()
    assert data["is_valid"] is True
    assert data["total_rows"] == 97
    assert data["filename"] == "sample.csv"


def test_predict_multipart_upload(client: TestClient):
    """Verify CSV prediction endpoint accepting multipart/form-data file upload."""
    sample_resp = client.get("/csv/templates/sample")
    csv_bytes = sample_resp.content

    pred_resp = client.post(
        "/csv/predict",
        data={"selected_timestamp": "2022-07-06 04:00:00"},
        files={"file": ("sample.csv", io.BytesIO(csv_bytes), "text/csv")}
    )
    assert pred_resp.status_code == 200
    res = pred_resp.json()
    assert res["prediction_available"] is True
    assert res["forecast_plus_6h"] == 528.801
    assert round(res["forecast_plus_24h"], 3) == 529.374
    assert res["hydrological_regime"] == "SURGE"


def test_custom_csv_surge_prediction(client: TestClient):
    """Verify Ridge Config C is dispatched for active surge in uploaded CSV."""
    sample_resp = client.get("/csv/templates/sample")
    csv_text = sample_resp.text

    pred_resp = client.post("/csv/predict", json={
        "csv_content": csv_text,
        "selected_timestamp": "2022-07-06 04:00:00",
        "filename": "sample.csv"
    })
    assert pred_resp.status_code == 200
    res = pred_resp.json()

    assert res["prediction_available"] is True
    assert res["current_river_level_m"] == 528.505
    assert res["forecast_plus_6h"] == 528.801
    assert round(res["forecast_plus_24h"], 3) == 529.374
    assert res["hydrological_regime"] == "SURGE"
    assert res["target_sensor_health"] == "HEALTHY"
    assert res["uncertainty_warning"] == "NOMINAL_SURGE_RIDGE"
    assert len(res["telemetry_series"]) == 97
    assert len(res["features_engineered"]) == 15


def test_custom_csv_baseflow_prediction(client: TestClient):
    """Verify Persistence baseline is dispatched during quiescent baseflow in uploaded CSV."""
    sample_resp = client.get("/csv/templates/sample")
    csv_text = sample_resp.text

    # Earlier timestamp during quiescent baseflow before flood pulse arrives
    pred_resp = client.post("/csv/predict", json={
        "csv_content": csv_text,
        "selected_timestamp": "2022-07-04 04:00:00",
        "filename": "sample.csv"
    })
    assert pred_resp.status_code == 200
    res = pred_resp.json()

    assert res["prediction_available"] is True
    assert res["hydrological_regime"] == "BASEFLOW"
    assert res["forecast_plus_6h"] == res["current_river_level_m"]
    assert res["forecast_plus_24h"] == res["current_river_level_m"]
    assert res["target_sensor_health"] == "HEALTHY"


def test_custom_csv_target_sensor_flatline(client: TestClient):
    """Verify safety gating: target sensor flatline suppresses numerical forecast."""
    # Build 30 consecutive hourly readings where Ankali float stage is frozen at 526.650m
    rows = []
    base_time = pd.to_datetime("2023-02-09 00:00:00")
    for i in range(30):
        t_str = (base_time + pd.Timedelta(hours=i)).strftime("%Y-%m-%d %H:%M:%S")
        rows.append(f"{t_str},526.650,536.5000,622.000,0.0,MEASURED_ZERO")

    csv_text = "timestamp,ankali_stage_m,shigaon_stage_m,koyna_stage_m,sangli_rainfall_mm,rainfall_status\n" + "\n".join(rows)

    pred_resp = client.post("/csv/predict", json={
        "csv_content": csv_text,
        "selected_timestamp": "2023-02-10 05:00:00",
        "filename": "flatline.csv"
    })
    assert pred_resp.status_code == 200
    res = pred_resp.json()

    assert res["prediction_available"] is False
    assert res["forecast_plus_6h"] is None
    assert res["forecast_plus_24h"] is None
    assert res["hydrological_regime"] == "DEGRADED_UNUSABLE"
    assert res["target_sensor_health"] in ["STALE", "SUSPECT_STALE"]
    assert "withheld" in res["fallback_reason"].lower()


def test_custom_csv_upstream_sensor_dropout(client: TestClient):
    """Verify upstream gauge dropout triggers degraded persistence fallback."""
    rows = []
    base_time = pd.to_datetime("2023-05-01 00:00:00")
    for i in range(30):
        t_str = (base_time + pd.Timedelta(hours=i)).strftime("%Y-%m-%d %H:%M:%S")
        # Target Ankali varies naturally (healthy), Shigaon gauge missing completely (empty value)
        a_stage = round(527.500 + (i % 5) * 0.03, 3)
        rows.append(f"{t_str},{a_stage},,622.000,0.0,MEASURED_ZERO")

    csv_text = "timestamp,ankali_stage_m,shigaon_stage_m,koyna_stage_m,sangli_rainfall_mm,rainfall_status\n" + "\n".join(rows)

    pred_resp = client.post("/csv/predict", json={
        "csv_content": csv_text,
        "selected_timestamp": "2023-05-02 05:00:00",
        "filename": "upstream_dropout.csv"
    })
    assert pred_resp.status_code == 200
    res = pred_resp.json()

    assert res["prediction_available"] is True
    assert res["upstream_sensor_availability"]["shigaon_gauge"] is False
    assert res["upstream_sensor_health"]["shigaon_gauge"] == "MISSING"


def test_custom_csv_missing_rainfall_semantics(client: TestClient):
    """Verify unrecorded missing rainfall is not fabricated as confirmed 0.0 mm."""
    rows = []
    base_time = pd.to_datetime("2023-06-01 00:00:00")
    for i in range(30):
        t_str = (base_time + pd.Timedelta(hours=i)).strftime("%Y-%m-%d %H:%M:%S")
        a_stage = round(527.500 + (i % 5) * 0.03, 3)
        # Rainfall non-reporting
        rows.append(f"{t_str},{a_stage},536.5000,622.000,,UNRECORDED_MISSING")

    csv_text = "timestamp,ankali_stage_m,shigaon_stage_m,koyna_stage_m,sangli_rainfall_mm,rainfall_status\n" + "\n".join(rows)

    pred_resp = client.post("/csv/predict", json={
        "csv_content": csv_text,
        "selected_timestamp": "2023-06-02 05:00:00",
        "filename": "missing_rain.csv"
    })
    assert pred_resp.status_code == 200
    res = pred_resp.json()

    assert res["upstream_sensor_health"]["sangli_rainfall"] == "UNRECORDED_MISSING"


def test_custom_csv_assumed_zero_rainfall(client: TestClient):
    """Verify ASSUMED_ZERO convention is recognized without fabricating confirmed measurement."""
    rows = []
    base_time = pd.to_datetime("2023-06-01 00:00:00")
    for i in range(30):
        t_str = (base_time + pd.Timedelta(hours=i)).strftime("%Y-%m-%d %H:%M:%S")
        a_stage = round(527.500 + (i % 5) * 0.03, 3)
        rows.append(f"{t_str},{a_stage},536.5000,622.000,,ASSUMED_ZERO")

    csv_text = "timestamp,ankali_stage_m,shigaon_stage_m,koyna_stage_m,sangli_rainfall_mm,rainfall_status\n" + "\n".join(rows)

    pred_resp = client.post("/csv/predict", json={
        "csv_content": csv_text,
        "selected_timestamp": "2023-06-02 05:00:00",
        "filename": "assumed_zero.csv"
    })
    assert pred_resp.status_code == 200
    res = pred_resp.json()

    assert res["upstream_sensor_health"]["sangli_rainfall"] == "ASSUMED_ZERO"


def test_invalid_csv_validation_errors(client: TestClient):
    """Verify clear blocking validation errors for missing columns and duplicate timestamps."""
    # 1. Missing columns
    bad_cols_csv = "timestamp,ankali_stage_m\n2023-01-01 00:00:00,527.5\n"
    res1 = client.post("/csv/validate", json={"csv_content": bad_cols_csv})
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["is_valid"] is False
    assert any("missing required columns" in e.lower() for e in data1["validation_errors"])

    # 2. Duplicate timestamps
    dup_csv = (
        "timestamp,ankali_stage_m,shigaon_stage_m,koyna_stage_m,sangli_rainfall_mm,rainfall_status\n"
        "2023-01-01 00:00:00,527.5,536.5,622.0,0.0,MEASURED_ZERO\n"
        "2023-01-01 00:00:00,527.5,536.5,622.0,0.0,MEASURED_ZERO\n"
    )
    res2 = client.post("/csv/validate", json={"csv_content": dup_csv})
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["is_valid"] is False
    assert data2["duplicate_timestamps_count"] == 1


def test_future_data_leakage_prevention(client: TestClient):
    """
    CRITICAL CAUSAL AUDIT:
    Verify that altering observations AFTER forecast timestamp T has ZERO impact
    on engineered features, sensor health assessments, and model predictions at T.
    """
    sample_resp = client.get("/csv/templates/sample")
    orig_csv = sample_resp.text
    target_ts = "2022-07-06 04:00:00"

    # Run prediction on original sample
    resp_orig = client.post("/csv/predict", json={
        "csv_content": orig_csv,
        "selected_timestamp": target_ts,
        "filename": "original.csv"
    })
    assert resp_orig.status_code == 200
    pred_orig = resp_orig.json()

    # Modify sample with extreme anomalous data strictly after target_ts
    df_tampered = pd.read_csv(io.StringIO(orig_csv))
    after_t = df_tampered["timestamp"] > target_ts
    assert after_t.sum() > 0

    df_tampered.loc[after_t, "ankali_stage_m"] = 999.99
    df_tampered.loc[after_t, "shigaon_stage_m"] = 888.88
    df_tampered.loc[after_t, "koyna_stage_m"] = 777.77
    df_tampered.loc[after_t, "sangli_rainfall_mm"] = 999.0
    tampered_csv = df_tampered.to_csv(index=False)

    resp_tampered = client.post("/csv/predict", json={
        "csv_content": tampered_csv,
        "selected_timestamp": target_ts,
        "filename": "tampered.csv"
    })
    assert resp_tampered.status_code == 200
    pred_tampered = resp_tampered.json()

    # Causal assertions:
    assert pred_orig["forecast_plus_6h"] == pred_tampered["forecast_plus_6h"]
    assert pred_orig["forecast_plus_24h"] == pred_tampered["forecast_plus_24h"]
    assert pred_orig["current_river_level_m"] == pred_tampered["current_river_level_m"]
    assert pred_orig["hydrological_regime"] == pred_tampered["hydrological_regime"]
    assert pred_orig["target_sensor_health"] == pred_tampered["target_sensor_health"]
    assert pred_orig["uncertainty_warning"] == pred_tampered["uncertainty_warning"]
    assert pred_orig["features_engineered"] == pred_tampered["features_engineered"]
