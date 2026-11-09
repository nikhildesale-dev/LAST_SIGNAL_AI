"""
LAST_SIGNAL_AI: FastAPI Route Handlers
"""

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
import pandas as pd
from fastapi import APIRouter, HTTPException, Query, Request, status
from fastapi.responses import FileResponse

from src.features import FEATURES_SCHEMA
from src.csv_service import CustomCsvService
from .schemas import (
    HealthResponse,
    ModelInfoResponse,
    PredictRequest,
    PredictResponse,
    ScenarioItem,
    ScenariosResponse,
    TelemetryHistoryResponse,
    TelemetryPoint,
    CsvValidateRequest,
    CsvValidationResponse,
    CsvPredictRequest,
    CsvPredictResponse,
)

router = APIRouter()


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Application Health & Model Status",
    description="Returns the operational health of the FastAPI service and model-loading status."
)
def get_health(request: Request) -> HealthResponse:
    forecaster = getattr(request.app.state, "forecaster", None)
    is_loaded = forecaster is not None and hasattr(forecaster, "models") and len(forecaster.models) > 0
    
    return HealthResponse(
        status="HEALTHY" if is_loaded else "DEGRADED",
        model_loaded=is_loaded,
        horizons_hours=[6, 24],
        version="2.0.0",
        timestamp=datetime.now(timezone.utc).isoformat()
    )


@router.get(
    "/model-info",
    response_model=ModelInfoResponse,
    status_code=status.HTTP_200_OK,
    summary="Model Metadata & Feature Schemas",
    description="Returns model architecture details, required input features, and known operational limitations."
)
def get_model_info(request: Request) -> ModelInfoResponse:
    forecaster = getattr(request.app.state, "forecaster", None)
    if forecaster is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Forecaster engine is not initialized in application state."
        )
        
    return ModelInfoResponse(
        service_name="LAST_SIGNAL_AI River-Level Forecasting Service",
        model_version="2.0.0-hardened",
        architecture="Gated Dual-Regime Forecaster (Persistence for Baseflow, Multi-Station Ridge for Surge)",
        target_station="Ankali Bridge (Krishna River Basin)",
        upstream_stations=["Shigaon (Warna River)", "Koyna_1 (Koyna Dam Reservoir)"],
        rainfall_station="SANGLI (Maharashtra Rainfall Network)",
        horizons_hours=[6, 24],
        features_schema=forecaster.features_schema,
        supported_regimes=["BASEFLOW", "SURGE", "DEGRADED", "DEGRADED_UNUSABLE"],
        known_limitations=[
            "Predicts continuous water stage (meters), not verified flood disaster occurrence or levee overtopping.",
            "Requires cross-sectional hydraulic geometry (rating curves) to convert stage to discharge (Q).",
            "Downstream gauges (Narsobawadi, Kurundwad) are not integrated due to historical telemetry dropouts.",
            "Withholds numerical forecasts when target sensor flatlines (>=24h invariant float) or telemetry latency exceeds 3.0h."
        ]
    )


@router.post(
    "/predict",
    response_model=PredictResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate River-Level Forecast",
    description="Accepts latest historical observations and engineered features, generating +6h and +24h water level forecasts."
)
def predict_river_level(payload: PredictRequest, request: Request) -> PredictResponse:
    forecaster = getattr(request.app.state, "forecaster", None)
    if forecaster is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Forecaster engine is not initialized in application state."
        )
        
    try:
        result = forecaster.predict(
            current_stage_m=payload.current_stage_m,
            current_time=payload.prediction_timestamp,
            features=payload.features,
            history_stages=payload.history_stages,
            history_timestamps=payload.history_timestamps,
            history_shigaon_stages=payload.history_shigaon_stages,
            history_shigaon_timestamps=payload.history_shigaon_timestamps,
            history_koyna_stages=payload.history_koyna_stages,
            history_koyna_timestamps=payload.history_koyna_timestamps,
            rainfall_measured_mm=payload.rainfall_measured_mm
        )
        return PredictResponse(**result)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Inference error processing telemetry inputs: {str(exc)}"
        )


@router.get(
    "/telemetry/scenarios",
    response_model=ScenariosResponse,
    status_code=status.HTTP_200_OK,
    summary="List Pre-Configured Hydrological Episodes",
    description="Returns curated historical episodes representing Baseflow, Surge, Sensor Flatlines, and Upstream Outages."
)
def get_telemetry_scenarios(request: Request) -> ScenariosResponse:
    pilot_df: pd.DataFrame = getattr(request.app.state, "pilot_data", None)
    if pilot_df is None or len(pilot_df) == 0:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Pilot dataset not loaded in application state."
        )

    scenario_defs = [
        ("2023-03-15 12:00:00", "Nominal Dry Baseflow", "Quiescent non-monsoon baseflow condition. Upstream Warna deltas near zero. Persistence engine active.", "BASEFLOW"),
        ("2022-07-06 04:00:00", "Monsoon Surge Pulse", "Active flood pulse from Shigaon Warna rise and catchment rainfall. Multi-Station Ridge engine active.", "SURGE"),
        ("2023-02-09 18:00:00", "Target Sensor Flatline (EP_05)", "Ankali Bridge float stage frozen at 526.65m for 26h with zero variance. Forecast safely withheld.", "STALE_FAULT"),
        ("2023-11-18 06:00:00", "Stable River Plateau (EP_07)", "Ankali Bridge stage invariant for 13h during stable natural recession. SUSPECT_STALE warning issued.", "PLATEAU_WARNING"),
        ("2022-02-12 18:00:00", "Upstream Gauge Dropout", "Ankali Bridge healthy but Shigaon gauge telemetry is missing. Upstream availability flag set to false.", "DROPOUT"),
    ]

    items: List[ScenarioItem] = []
    for target_time, name, desc, cat in scenario_defs:
        sub = pilot_df[pilot_df["timestamp"] == target_time]
        if len(sub) == 0:
            continue
        idx = sub.index[0]
        row = sub.iloc[0]
        feats = {k: (None if pd.isna(row[k]) else float(row[k])) for k in FEATURES_SCHEMA}
        curr = None if pd.isna(row["river_mean"]) else float(row["river_mean"])
        
        # Nominal baseflow episode uses 18h lookback to verify quiescent dynamics without false flatline trip
        start_idx = max(0, idx - 18) if target_time == "2023-03-15 12:00:00" else max(0, idx - 48)
        hist = pilot_df.iloc[start_idx:idx]
        hist_st = [float(x) for x in hist["river_mean"] if pd.notna(x)]
        hist_ti = [str(x) for x in hist["timestamp"] if pd.notna(x)]

        shig_sub = hist[hist["shigaon_mean"].notna()]
        hist_shig = [float(x) for x in shig_sub["shigaon_mean"]]
        hist_shig_ti = [str(x) for x in shig_sub["timestamp"]]

        koy_sub = hist[hist["koyna_1_mean"].notna()]
        hist_koy = [float(x) for x in koy_sub["koyna_1_mean"]]
        hist_koy_ti = [str(x) for x in koy_sub["timestamp"]]
        rain_meas = None if ("rainfall_measured_mm" not in row or pd.isna(row["rainfall_measured_mm"])) else float(row["rainfall_measured_mm"])
        
        items.append(ScenarioItem(
            id=cat.lower() + "_" + target_time.replace(" ", "_").replace(":", ""),
            name=name,
            description=desc,
            category=cat,
            prediction_timestamp=str(row["timestamp"]),
            current_stage_m=curr,
            features=feats,
            history_stages=hist_st,
            history_timestamps=hist_ti,
            history_shigaon_stages=hist_shig,
            history_shigaon_timestamps=hist_shig_ti,
            history_koyna_stages=hist_koy,
            history_koyna_timestamps=hist_koy_ti,
            rainfall_measured_mm=rain_meas
        ))

    return ScenariosResponse(scenarios=items)


@router.get(
    "/telemetry/history",
    response_model=TelemetryHistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Historical Telemetry Series",
    description="Returns chronological telemetry observations for Ankali Bridge, Shigaon, Koyna_1, and Sangli rainfall with exact missing indicators."
)
def get_telemetry_history(
    request: Request,
    start_time: Optional[str] = Query(None, description="Start timestamp (YYYY-MM-DD HH:MM:SS)"),
    end_time: Optional[str] = Query(None, description="End timestamp (YYYY-MM-DD HH:MM:SS)"),
    scenario_id: Optional[str] = Query(None, description="Center window around this scenario timestamp"),
    limit: int = Query(default=168, ge=24, le=720, description="Max observations to return")
) -> TelemetryHistoryResponse:
    pilot_df: pd.DataFrame = getattr(request.app.state, "pilot_data", None)
    if pilot_df is None or len(pilot_df) == 0:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Pilot dataset not loaded in application state."
        )

    df_slice = pilot_df

    if scenario_id:
        scenario_times = {
            "baseflow": "2023-03-15 12:00:00",
            "surge": "2022-07-06 04:00:00",
            "stale_fault": "2023-02-09 18:00:00",
            "plateau_warning": "2023-11-18 06:00:00",
            "dropout": "2022-02-12 18:00:00"
        }
        target_ts = None
        for k, v in scenario_times.items():
            if scenario_id.startswith(k):
                target_ts = v
                break
        if target_ts:
            match_rows = pilot_df[pilot_df["timestamp"] == target_ts]
            if len(match_rows) > 0:
                center_idx = match_rows.index[0]
                start_idx = max(0, center_idx - 72)
                end_idx = min(len(pilot_df), center_idx + 25)
                df_slice = pilot_df.iloc[start_idx:end_idx]
    elif start_time or end_time:
        if start_time:
            df_slice = df_slice[df_slice["timestamp"] >= start_time]
        if end_time:
            df_slice = df_slice[df_slice["timestamp"] <= end_time]
        df_slice = df_slice.tail(limit)
    else:
        df_slice = df_slice.tail(limit)

    series_list: List[TelemetryPoint] = []
    for _, row in df_slice.iterrows():
        ankali_val = None if pd.isna(row["river_mean"]) else round(float(row["river_mean"]), 4)
        shigaon_val = None if pd.isna(row["shigaon_mean"]) else round(float(row["shigaon_mean"]), 4)
        koyna_val = None if pd.isna(row["koyna_1_mean"]) else round(float(row["koyna_1_mean"]), 4)
        rain_val = None if pd.isna(row["rainfall_measured_mm"]) else round(float(row["rainfall_measured_mm"]), 2)

        if pd.notna(row.get("rainfall_measured_mm")):
            rain_stat = "MEASURED_POSITIVE" if float(row["rainfall_measured_mm"]) > 0.0 else "MEASURED_ZERO"
        elif pd.notna(row.get("rainfall_imputed_zero_mm")) and float(row["rainfall_imputed_zero_mm"]) == 0.0:
            rain_stat = "ASSUMED_ZERO"
        else:
            rain_stat = "UNRECORDED_MISSING"

        series_list.append(TelemetryPoint(
            timestamp=str(row["timestamp"]),
            ankali_stage_m=ankali_val,
            shigaon_stage_m=shigaon_val,
            koyna_stage_m=koyna_val,
            rainfall_mm=rain_val,
            rainfall_status=rain_stat,
            ankali_avail=bool(row["ankali_avail"]) if "ankali_avail" in row else (ankali_val is not None),
            shigaon_avail=bool(row["shigaon_avail"]) if "shigaon_avail" in row else (shigaon_val is not None),
            koyna_avail=bool(row["koyna_avail"]) if "koyna_avail" in row else (koyna_val is not None),
            rainfall_avail=pd.notna(row["rainfall_measured_mm"])
        ))

    return TelemetryHistoryResponse(
        station="Ankali Bridge (Krishna River Basin)",
        count=len(series_list),
        start_time=series_list[0].timestamp if series_list else "",
        end_time=series_list[-1].timestamp if series_list else "",
        series=series_list
    )


@router.get(
    "/csv/templates/blank",
    summary="Download Blank CSV Template",
    description="Returns a downloadable blank CSV file with required column headers."
)
def download_blank_template():
    template_path = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "data", "templates", "blank_telemetry_template.csv")
    )
    if not os.path.exists(template_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Blank template file not found.")
    return FileResponse(
        template_path,
        media_type="text/csv",
        filename="LAST_SIGNAL_AI_blank_telemetry_template.csv"
    )


@router.get(
    "/csv/templates/sample",
    summary="Download Sample Historical Telemetry CSV",
    description="Returns genuine historical telemetry from the Krishna Basin pilot dataset for demonstration."
)
def download_sample_template():
    sample_path = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "data", "templates", "sample_historical_telemetry.csv")
    )
    if not os.path.exists(sample_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sample template file not found.")
    return FileResponse(
        sample_path,
        media_type="text/csv",
        filename="LAST_SIGNAL_AI_sample_historical_telemetry.csv"
    )


@router.post(
    "/csv/validate",
    response_model=CsvValidationResponse,
    status_code=status.HTTP_200_OK,
    summary="Validate Uploaded Telemetry CSV",
    description="Validates CSV headers, data types, duplicate timestamps, and computes telemetry availability stats. Accepts JSON or multipart/form-data."
)
async def validate_telemetry_csv(request: Request) -> CsvValidationResponse:
    content_type = request.headers.get("content-type", "")
    csv_content = ""
    filename = "custom_telemetry.csv"

    if "multipart/form-data" in content_type:
        form = await request.form()
        file_obj = form.get("file")
        if file_obj is not None and hasattr(file_obj, "read"):
            csv_bytes = await file_obj.read()
            csv_content = csv_bytes.decode("utf-8", errors="replace")
            filename = getattr(file_obj, "filename", "custom_telemetry.csv")
        elif "csv_content" in form:
            csv_content = str(form.get("csv_content"))
            filename = str(form.get("filename", "custom_telemetry.csv"))
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No file or CSV content provided in form data.")
    else:
        try:
            payload = await request.json()
            csv_content = payload.get("csv_content", "")
            filename = payload.get("filename", "custom_telemetry.csv")
        except Exception:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid JSON payload.")

    if not csv_content:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="CSV content cannot be empty.")

    res = CustomCsvService.parse_and_validate_csv(csv_content, filename=filename)
    return CsvValidationResponse(**res.to_dict())


@router.post(
    "/csv/predict",
    response_model=CsvPredictResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate Predictions from Custom CSV",
    description="Executes causal dual-regime flood forecasting on uploaded telemetry up to selected timestamp T. Accepts JSON or multipart/form-data."
)
async def predict_from_custom_csv(request: Request) -> CsvPredictResponse:
    forecaster = getattr(request.app.state, "forecaster", None)
    if forecaster is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Forecaster engine is not initialized in application state."
        )

    content_type = request.headers.get("content-type", "")
    csv_content = ""
    filename = "custom_telemetry.csv"
    selected_timestamp = ""

    if "multipart/form-data" in content_type:
        form = await request.form()
        selected_timestamp = str(form.get("selected_timestamp", "")).strip()
        file_obj = form.get("file")
        if file_obj is not None and hasattr(file_obj, "read"):
            csv_bytes = await file_obj.read()
            csv_content = csv_bytes.decode("utf-8", errors="replace")
            filename = getattr(file_obj, "filename", "custom_telemetry.csv")
        elif "csv_content" in form:
            csv_content = str(form.get("csv_content"))
            filename = str(form.get("filename", "custom_telemetry.csv"))
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No file or CSV content provided in form data.")
    else:
        try:
            payload = await request.json()
            csv_content = payload.get("csv_content", "")
            selected_timestamp = payload.get("selected_timestamp", "")
            filename = payload.get("filename", "custom_telemetry.csv")
        except Exception:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid JSON payload.")

    if not csv_content:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="CSV content cannot be empty.")
    if not selected_timestamp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Selected forecast issuance timestamp T is required.")

    try:
        result = CustomCsvService.execute_forecast_from_csv(
            csv_input=csv_content,
            selected_timestamp=selected_timestamp,
            forecaster=forecaster,
            filename=filename
        )
        return CsvPredictResponse(**result)
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(val_err)
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error executing CSV forecast: {str(exc)}"
        )



