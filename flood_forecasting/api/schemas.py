"""
LAST_SIGNAL_AI: FastAPI Pydantic Request & Response Schemas
"""

from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(..., description="Overall service status (e.g. HEALTHY)")
    model_loaded: bool = Field(..., description="Whether pre-trained forecaster models are in memory")
    horizons_hours: List[int] = Field(default=[6, 24], description="Supported forecast lead times in hours")
    version: str = Field(..., description="Application semantic version")
    timestamp: str = Field(..., description="Current server timestamp")


class ModelInfoResponse(BaseModel):
    service_name: str
    model_version: str
    architecture: str
    target_station: str
    upstream_stations: List[str]
    rainfall_station: str
    horizons_hours: List[int]
    features_schema: List[str]
    supported_regimes: List[str]
    known_limitations: List[str]


class PredictRequest(BaseModel):
    current_stage_m: Optional[float] = Field(
        None,
        description="Current observed water level at Ankali Bridge target gauge in meters."
    )
    prediction_timestamp: str = Field(
        ...,
        description="ISO 8601 observation timestamp (e.g. '2023-07-20T12:00:00')."
    )
    features: Dict[str, Optional[float]] = Field(
        default_factory=dict,
        description="Engineered hydrological feature vector matching the 15-feature schema."
    )
    history_stages: Optional[List[float]] = Field(
        default=None,
        description="List of consecutive prior hourly water level observations at Ankali Bridge for flatline detection."
    )
    history_timestamps: Optional[List[str]] = Field(
        default=None,
        description="List of prior observation timestamps corresponding to history_stages."
    )
    history_shigaon_stages: Optional[List[float]] = Field(
        default=None,
        description="List of consecutive prior hourly water level observations at Shigaon for flatline detection."
    )
    history_shigaon_timestamps: Optional[List[str]] = Field(
        default=None,
        description="List of prior observation timestamps corresponding to history_shigaon_stages."
    )
    history_koyna_stages: Optional[List[float]] = Field(
        default=None,
        description="List of consecutive prior hourly water level observations at Koyna_1 for flatline detection."
    )
    history_koyna_timestamps: Optional[List[str]] = Field(
        default=None,
        description="List of prior observation timestamps corresponding to history_koyna_stages."
    )
    rainfall_measured_mm: Optional[float] = Field(
        default=None,
        description="Explicitly recorded rainfall from physical rain gauge, if available (e.g. 0.0 for confirmed dry weather)."
    )


class PredictResponse(BaseModel):
    prediction_available: bool = Field(
        ...,
        description="Whether a numerical forecast was emitted. False if withheld due to sensor faults."
    )
    forecast_plus_6h: Optional[float] = Field(
        None,
        description="Predicted water level at +6 hours in meters."
    )
    forecast_plus_24h: Optional[float] = Field(
        None,
        description="Predicted water level at +24 hours in meters."
    )
    current_river_level_m: Optional[float] = Field(
        None,
        description="Supplied current water level at Ankali Bridge."
    )
    hydrological_regime: str = Field(
        ...,
        description="Active hydrological state: BASEFLOW, SURGE, DEGRADED, or DEGRADED_UNUSABLE."
    )
    target_sensor_health: str = Field(
        ...,
        description="Target gauge health diagnostic: HEALTHY, SUSPECT_STALE, STALE, or MISSING."
    )
    upstream_sensor_availability: Dict[str, bool] = Field(
        ...,
        description="Individual availability booleans for upstream stations and rainfall gauge."
    )
    upstream_sensor_health: Optional[Dict[str, str]] = Field(
        default=None,
        description="Detailed health per upstream station: HEALTHY, STABLE_BUT_PLAUSIBLE, SUSPECT_FLATLINE, STALE, MISSING."
    )
    fallback_reason: Optional[str] = Field(
        None,
        description="Explanation of persistence fallback or forecast withholding policy."
    )
    prediction_timestamp: str = Field(
        ...,
        description="Timestamp for which the prediction was executed."
    )
    uncertainty_warning: Optional[str] = Field(
        None,
        description="Confidence or uncertainty warning flag (e.g. PROLONGED_CONSTANT_STAGE)."
    )
    feature_statuses: Optional[Dict[str, str]] = Field(
        default=None,
        description="Display availability status for each feature: OK, TELEMETRY_DROPOUT, INSUFFICIENT_HISTORY, ZERO_IMPUTED, ASSUMED_ZERO, MEASURED_ZERO, MEASURED_POSITIVE, or MISSING."
    )


class TelemetryPoint(BaseModel):
    timestamp: str = Field(..., description="ISO 8601 observation timestamp")
    ankali_stage_m: Optional[float] = Field(None, description="Ankali Bridge stage in meters (null if missing)")
    shigaon_stage_m: Optional[float] = Field(None, description="Shigaon upstream Warna stage in meters (null if missing)")
    koyna_stage_m: Optional[float] = Field(None, description="Koyna_1 reservoir stage in meters (null if missing)")
    rainfall_mm: Optional[float] = Field(None, description="Sangli rainfall in mm (null if non-reporting/missing)")
    rainfall_status: Optional[str] = Field(None, description="Detailed rainfall telemetry status: MEASURED_POSITIVE, MEASURED_ZERO, ASSUMED_ZERO, or UNRECORDED_MISSING")
    ankali_avail: bool = Field(True, description="Whether Ankali telemetry was available")
    shigaon_avail: bool = Field(True, description="Whether Shigaon telemetry was available")
    koyna_avail: bool = Field(True, description="Whether Koyna telemetry was available")
    rainfall_avail: bool = Field(True, description="Whether rainfall telemetry was available")


class TelemetryHistoryResponse(BaseModel):
    station: str = Field(default="Ankali Bridge (Krishna River Basin)")
    count: int = Field(..., description="Number of historical time points returned")
    start_time: str = Field(..., description="Start observation timestamp")
    end_time: str = Field(..., description="End observation timestamp")
    series: List[TelemetryPoint] = Field(..., description="Chronological series of telemetry observations")


class ScenarioItem(BaseModel):
    id: str = Field(..., description="Scenario unique identifier")
    name: str = Field(..., description="Human-readable title")
    description: str = Field(..., description="Hydrological scenario description")
    category: str = Field(..., description="BASEFLOW, SURGE, STALE_FAULT, PLATEAU_WARNING, or DROPOUT")
    prediction_timestamp: str = Field(..., description="Target timestamp for prediction execution")
    current_stage_m: Optional[float] = Field(None, description="Observed stage at prediction time")
    features: Dict[str, Optional[float]] = Field(..., description="Hydrological 15-feature dictionary")
    history_stages: Optional[List[float]] = Field(None, description="Preceding hourly stage history")
    history_timestamps: Optional[List[str]] = Field(None, description="Preceding hourly timestamps")
    history_shigaon_stages: Optional[List[float]] = Field(None, description="Preceding hourly stage history for Shigaon")
    history_shigaon_timestamps: Optional[List[str]] = Field(None, description="Preceding hourly timestamps for Shigaon")
    history_koyna_stages: Optional[List[float]] = Field(None, description="Preceding hourly stage history for Koyna_1")
    history_koyna_timestamps: Optional[List[str]] = Field(None, description="Preceding hourly timestamps for Koyna_1")
    rainfall_measured_mm: Optional[float] = Field(None, description="Direct physical rainfall measurement if recorded")


class ScenariosResponse(BaseModel):
    scenarios: List[ScenarioItem] = Field(..., description="Pre-configured historical episodes from Krishna Basin audit")


class CsvStationStats(BaseModel):
    station_name: str = Field(..., description="Human-readable station identifier")
    unit: str = Field(..., description="Measurement unit (meters or mm)")
    total_records: int = Field(..., description="Total rows in series")
    valid_count: int = Field(..., description="Valid non-null readings count")
    missing_count: int = Field(..., description="Missing null readings count")
    missing_pct: float = Field(..., description="Percentage of missing readings")
    min_val: Optional[float] = Field(None, description="Minimum observed reading")
    max_val: Optional[float] = Field(None, description="Maximum observed reading")


class CsvValidationResponse(BaseModel):
    is_valid: bool = Field(..., description="Whether CSV passed structural and data-type validation")
    filename: str = Field(..., description="Uploaded file name")
    total_rows: int = Field(..., description="Total rows parsed")
    start_timestamp: Optional[str] = Field(None, description="Earliest observation timestamp")
    end_timestamp: Optional[str] = Field(None, description="Latest observation timestamp")
    duplicate_timestamps_count: int = Field(0, description="Count of duplicate timestamps")
    validation_errors: List[str] = Field(default_factory=list, description="Critical blocking validation errors")
    validation_warnings: List[str] = Field(default_factory=list, description="Non-blocking data quality warnings")
    station_stats: Dict[str, CsvStationStats] = Field(default_factory=dict, description="Summary statistics per telemetry station")
    rainfall_status_counts: Dict[str, int] = Field(default_factory=dict, description="Counts by rainfall status flag")
    available_timestamps: List[str] = Field(default_factory=list, description="All observation timestamps in file")
    timestamps_with_sufficient_history: List[str] = Field(default_factory=list, description="Timestamps with >= 24h lookback for complete feature engineering")


class CsvValidateRequest(BaseModel):
    csv_content: str = Field(..., description="Raw CSV text content")
    filename: Optional[str] = Field("custom_telemetry.csv", description="Original file name")


class CsvPredictRequest(BaseModel):
    csv_content: str = Field(..., description="Raw CSV text content")
    selected_timestamp: str = Field(..., description="Chosen forecast issuance timestamp T")
    filename: Optional[str] = Field("custom_telemetry.csv", description="Original file name")


class CsvPredictResponse(PredictResponse):
    filename: str = Field(..., description="Processed CSV file name")
    selected_timestamp: str = Field(..., description="Chosen forecast issuance timestamp T")
    telemetry_series: List[TelemetryPoint] = Field(default_factory=list, description="Timeline observations for chart visualization")
    features_engineered: Dict[str, Optional[float]] = Field(default_factory=dict, description="Derived 15-feature vector")



