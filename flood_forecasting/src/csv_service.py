"""
LAST_SIGNAL_AI: Custom CSV Validation and Prediction Service

Provides rigorous ingestion, schema validation, and causal feature assembly
for user-uploaded multi-station hydrological CSV files.
Reuses the production FeatureEngineer and RiverLevelForecaster pipelines.
"""

import io
from typing import Any, Dict, List, Optional, Tuple, Union
import numpy as np
import pandas as pd

from src.features import FeatureEngineer, FEATURES_SCHEMA
from src.forecaster import RiverLevelForecaster, SensorStatus, HydrologicalRegime


REQUIRED_CSV_COLUMNS = [
    "timestamp",
    "ankali_stage_m",
    "shigaon_stage_m",
    "koyna_stage_m",
    "sangli_rainfall_mm",
    "rainfall_status"
]

VALID_RAINFALL_STATUSES = {
    "MEASURED_POSITIVE",
    "MEASURED_ZERO",
    "ASSUMED_ZERO",
    "MISSING",
    "UNRECORDED_MISSING"
}


class CsvValidationResult:
    """Holds data validation results and summary telemetry statistics."""

    def __init__(
        self,
        is_valid: bool,
        filename: str,
        total_rows: int,
        start_timestamp: Optional[str] = None,
        end_timestamp: Optional[str] = None,
        duplicate_count: int = 0,
        errors: Optional[List[str]] = None,
        warnings: Optional[List[str]] = None,
        station_stats: Optional[Dict[str, Dict[str, Any]]] = None,
        rainfall_status_counts: Optional[Dict[str, int]] = None,
        available_timestamps: Optional[List[str]] = None,
        sufficient_history_timestamps: Optional[List[str]] = None,
        df_cleaned: Optional[pd.DataFrame] = None
    ):
        self.is_valid = is_valid
        self.filename = filename
        self.total_rows = total_rows
        self.start_timestamp = start_timestamp
        self.end_timestamp = end_timestamp
        self.duplicate_count = duplicate_count
        self.errors = errors or []
        self.warnings = warnings or []
        self.station_stats = station_stats or {}
        self.rainfall_status_counts = rainfall_status_counts or {}
        self.available_timestamps = available_timestamps or []
        self.sufficient_history_timestamps = sufficient_history_timestamps or []
        self.df_cleaned = df_cleaned

    def to_dict(self) -> Dict[str, Any]:
        return {
            "is_valid": self.is_valid,
            "filename": self.filename,
            "total_rows": self.total_rows,
            "start_timestamp": self.start_timestamp,
            "end_timestamp": self.end_timestamp,
            "duplicate_timestamps_count": self.duplicate_count,
            "validation_errors": self.errors,
            "validation_warnings": self.warnings,
            "station_stats": self.station_stats,
            "rainfall_status_counts": self.rainfall_status_counts,
            "available_timestamps": self.available_timestamps,
            "timestamps_with_sufficient_history": self.sufficient_history_timestamps
        }


class CustomCsvService:
    """
    Ingests and validates uploaded CSV files and executes causal forecasting
    without modifying model parameters or introducing future-data leakage.
    """

    @classmethod
    def parse_and_validate_csv(
        cls,
        csv_input: Union[str, bytes, io.StringIO, pd.DataFrame],
        filename: str = "custom_telemetry.csv"
    ) -> CsvValidationResult:
        """
        Validates CSV content for required schema, data types, timestamp monotonicity,
        duplicate records, and missing telemetry ratios.
        """
        errors: List[str] = []
        warnings: List[str] = []

        # 1. Ingest into DataFrame
        try:
            if isinstance(csv_input, pd.DataFrame):
                df = csv_input.copy()
            elif isinstance(csv_input, bytes):
                df = pd.read_csv(io.BytesIO(csv_input))
            elif isinstance(csv_input, str):
                df = pd.read_csv(io.StringIO(csv_input))
            else:
                df = pd.read_csv(csv_input)
        except Exception as exc:
            return CsvValidationResult(
                is_valid=False,
                filename=filename,
                total_rows=0,
                errors=[f"Failed to parse CSV file: {str(exc)}"]
            )

        if df.empty or len(df) == 0:
            return CsvValidationResult(
                is_valid=False,
                filename=filename,
                total_rows=0,
                errors=["The uploaded CSV file is empty."]
            )

        # 2. Check required columns
        df.columns = [str(c).strip().lower() for c in df.columns]
        missing_cols = [c for c in REQUIRED_CSV_COLUMNS if c not in df.columns]
        if missing_cols:
            errors.append(
                f"Missing required columns: {', '.join(missing_cols)}. "
                f"Expected columns: {', '.join(REQUIRED_CSV_COLUMNS)}."
            )
            return CsvValidationResult(
                is_valid=False,
                filename=filename,
                total_rows=len(df),
                errors=errors
            )

        # 3. Validate and parse timestamps
        try:
            df["dt"] = pd.to_datetime(df["timestamp"], errors="coerce")
        except Exception as exc:
            errors.append(f"Timestamp column could not be parsed: {str(exc)}")
            return CsvValidationResult(
                is_valid=False,
                filename=filename,
                total_rows=len(df),
                errors=errors
            )

        null_timestamps = df["dt"].isna().sum()
        if null_timestamps > 0:
            errors.append(f"{null_timestamps} rows contain invalid or unparseable timestamps.")

        # Check duplicate timestamps
        duplicates = df["dt"].duplicated().sum()
        if duplicates > 0:
            errors.append(f"Found {duplicates} duplicate timestamps in the telemetry sequence.")

        # Check chronology
        is_sorted = df["dt"].is_monotonic_increasing
        if not is_sorted:
            warnings.append("Timestamps were not sorted chronologically. Automatically sorted in ascending order.")
            df = df.sort_values("dt").reset_index(drop=True)

        # Standardize timestamp string format
        df["timestamp"] = df["dt"].dt.strftime("%Y-%m-%d %H:%M:%S")

        # 4. Numeric column conversions and range validation
        numeric_cols = {
            "ankali_stage_m": ("Target River Gauge (Ankali)", "meters", 500.0, 560.0),
            "shigaon_stage_m": ("Upstream Gauge (Shigaon Warna)", "meters", 510.0, 570.0),
            "koyna_stage_m": ("Upstream Reservoir (Koyna_1)", "meters", 580.0, 660.0),
            "sangli_rainfall_mm": ("Catchment Rain Gauge (Sangli)", "mm", 0.0, 300.0)
        }

        station_stats: Dict[str, Dict[str, Any]] = {}

        for col, (label, unit, min_plausible, max_plausible) in numeric_cols.items():
            # Check for non-numeric conversion
            original_series = df[col]
            coerced = pd.to_numeric(original_series, errors="coerce")
            non_numeric_count = original_series.notna().sum() - coerced.notna().sum()
            if non_numeric_count > 0:
                errors.append(f"Column '{col}' contains {non_numeric_count} non-numeric invalid values.")

            df[col] = coerced

            valid_count = int(df[col].notna().sum())
            missing_count = int(df[col].isna().sum())
            total = len(df)
            missing_pct = round((missing_count / total) * 100.0, 2) if total > 0 else 0.0

            min_val = float(df[col].min()) if valid_count > 0 else None
            max_val = float(df[col].max()) if valid_count > 0 else None

            # Plausibility sanity checks
            if valid_count > 0 and min_val is not None and max_val is not None:
                if min_val < 0.0 and col == "sangli_rainfall_mm":
                    errors.append(f"Rainfall column '{col}' cannot contain negative values (found {min_val} mm).")
                elif min_val < min_plausible or max_val > max_plausible:
                    warnings.append(
                        f"Values in '{col}' ({min_val} to {max_val} {unit}) fall outside typical physical ranges "
                        f"for {label} ({min_plausible}–{max_plausible} {unit})."
                    )

            station_stats[col] = {
                "station_name": label,
                "unit": unit,
                "total_records": total,
                "valid_count": valid_count,
                "missing_count": missing_count,
                "missing_pct": missing_pct,
                "min_val": round(min_val, 3) if min_val is not None else None,
                "max_val": round(max_val, 3) if max_val is not None else None
            }

        # 5. Rainfall status validation
        df["rainfall_status"] = df["rainfall_status"].fillna("UNRECORDED_MISSING").astype(str).str.strip().str.upper()
        invalid_statuses = set(df["rainfall_status"].unique()) - VALID_RAINFALL_STATUSES
        if invalid_statuses:
            errors.append(
                f"Column 'rainfall_status' contains unrecognized values: {', '.join(invalid_statuses)}. "
                f"Valid options: {', '.join(sorted(VALID_RAINFALL_STATUSES))}."
            )

        # Semantics check: if measured rainfall > 0, status must not contradict
        pos_rain_mask = (df["sangli_rainfall_mm"] > 0) & (df["rainfall_status"] == "MEASURED_ZERO")
        if pos_rain_mask.sum() > 0:
            errors.append(
                f"{pos_rain_mask.sum()} rows report positive rainfall (> 0mm) but state rainfall_status='MEASURED_ZERO'."
            )

        rainfall_status_counts = {k: int(v) for k, v in df["rainfall_status"].value_counts().items()}

        # 6. Lookback history assessment
        timestamps = df["timestamp"].tolist()
        sufficient_history = []
        for idx, ts in enumerate(timestamps):
            # Need at least 24 preceding rows for 24h lag and delta features
            if idx >= 24:
                sufficient_history.append(ts)

        if len(df) < 25:
            warnings.append(
                f"Uploaded series contains {len(df)} records. Full causal feature engineering requires at least "
                "25 hourly observations for 24-hour lag and delta metrics. Features will use partial lookback."
            )

        is_valid = len(errors) == 0

        start_ts = timestamps[0] if timestamps else None
        end_ts = timestamps[-1] if timestamps else None

        return CsvValidationResult(
            is_valid=is_valid,
            filename=filename,
            total_rows=len(df),
            start_timestamp=start_ts,
            end_timestamp=end_ts,
            duplicate_count=int(duplicates),
            errors=errors,
            warnings=warnings,
            station_stats=station_stats,
            rainfall_status_counts=rainfall_status_counts,
            available_timestamps=timestamps,
            sufficient_history_timestamps=sufficient_history,
            df_cleaned=df if is_valid else None
        )

    @classmethod
    def execute_forecast_from_csv(
        cls,
        csv_input: Union[str, bytes, io.StringIO, pd.DataFrame],
        selected_timestamp: str,
        forecaster: RiverLevelForecaster,
        filename: str = "custom_telemetry.csv"
    ) -> Dict[str, Any]:
        """
        Executes causal flood forecasting for the chosen issuance timestamp T.
        Enforces strict causal filtering: observations after T are excluded from
        feature engineering and health checks to prevent future data leakage.
        """
        # Validate CSV first
        val_result = cls.parse_and_validate_csv(csv_input, filename=filename)
        if not val_result.is_valid:
            raise ValueError(f"CSV Validation failed: {'; '.join(val_result.errors)}")

        df = val_result.df_cleaned
        if df is None:
            raise ValueError("Parsed telemetry DataFrame is empty.")

        # Locate selected timestamp
        match_idx = df[df["timestamp"] == selected_timestamp].index
        if len(match_idx) == 0:
            raise ValueError(
                f"Selected timestamp '{selected_timestamp}' was not found in the uploaded CSV. "
                f"Available range: {val_result.start_timestamp} to {val_result.end_timestamp}."
            )

        idx = match_idx[0]

        # STRICT CAUSAL FILTER: Slice up to and including T
        # Observations strictly after T are ground truth only and cannot be accessed by features or model
        causal_df = df.iloc[: idx + 1].copy()

        # Extract current observation at T
        curr_row = causal_df.iloc[-1]
        curr_stage = float(curr_row["ankali_stage_m"]) if pd.notna(curr_row["ankali_stage_m"]) else None
        curr_shigaon = float(curr_row["shigaon_stage_m"]) if pd.notna(curr_row["shigaon_stage_m"]) else None
        curr_koyna = float(curr_row["koyna_stage_m"]) if pd.notna(curr_row["koyna_stage_m"]) else None
        curr_rain_meas = float(curr_row["sangli_rainfall_mm"]) if (
            pd.notna(curr_row["sangli_rainfall_mm"]) and curr_row["rainfall_status"] in ["MEASURED_POSITIVE", "MEASURED_ZERO"]
        ) else None

        # Preceding observations strictly before T
        stage_before = causal_df["ankali_stage_m"].iloc[:-1]
        shigaon_before = causal_df["shigaon_stage_m"].iloc[:-1]
        koyna_before = causal_df["koyna_stage_m"].iloc[:-1]

        # 1. River lags
        lags = FeatureEngineer.calculate_river_lags(stage_before)

        # 2. Stage deltas
        shig_deltas = FeatureEngineer.calculate_stage_deltas(shigaon_before, prefix="shigaon")
        koy_deltas = FeatureEngineer.calculate_stage_deltas(koyna_before, prefix="koyna")

        # 3. Rainfall features (respecting explicit rainfall semantics)
        def map_rainfall_value(r):
            status = r.get("rainfall_status", "UNRECORDED_MISSING")
            val = r.get("sangli_rainfall_mm")
            if status in ["MEASURED_POSITIVE", "MEASURED_ZERO"]:
                return float(val) if pd.notna(val) else 0.0
            elif status == "ASSUMED_ZERO":
                return 0.0
            else:
                return np.nan

        rain_series = causal_df.apply(map_rainfall_value, axis=1)
        rain_feats = FeatureEngineer.calculate_rainfall_features(rain_series)

        # Assemble feature vector
        features = {**lags, **shig_deltas, **koy_deltas, **rain_feats}

        # Lookback arrays for flatline / health analysis (up to 48 hours before T)
        h_start = max(0, len(stage_before) - 48)
        hist_ankali = [float(x) for x in stage_before.iloc[h_start:] if pd.notna(x)]
        hist_ankali_t = [str(x) for x in causal_df["timestamp"].iloc[:-1].iloc[h_start:]]

        hist_shig = [float(x) for x in shigaon_before.iloc[h_start:] if pd.notna(x)]
        hist_shig_t = [str(x) for x in causal_df["timestamp"].iloc[:-1].iloc[h_start:]]

        hist_koy = [float(x) for x in koyna_before.iloc[h_start:] if pd.notna(x)]
        hist_koy_t = [str(x) for x in causal_df["timestamp"].iloc[:-1].iloc[h_start:]]

        # Execute existing production forecaster
        prediction = forecaster.predict(
            current_stage_m=curr_stage,
            current_time=selected_timestamp,
            features=features,
            history_stages=hist_ankali,
            history_timestamps=hist_ankali_t,
            history_shigaon_stages=hist_shig,
            history_shigaon_timestamps=hist_shig_t,
            history_koyna_stages=hist_koy,
            history_koyna_timestamps=hist_koy_t,
            shigaon_stage_m=curr_shigaon,
            koyna_stage_m=curr_koyna,
            rainfall_measured_mm=curr_rain_meas
        )

        # Assemble full chart telemetry from entire uploaded file
        # Rows <= T: historical observations
        # Rows > T: subsequent ground truth reference
        telemetry_series = []
        for _, row in df.iterrows():
            ts_str = str(row["timestamp"])
            a_val = float(row["ankali_stage_m"]) if pd.notna(row["ankali_stage_m"]) else None
            s_val = float(row["shigaon_stage_m"]) if pd.notna(row["shigaon_stage_m"]) else None
            k_val = float(row["koyna_stage_m"]) if pd.notna(row["koyna_stage_m"]) else None
            r_val = float(row["sangli_rainfall_mm"]) if pd.notna(row["sangli_rainfall_mm"]) else None
            r_stat = str(row["rainfall_status"]) if pd.notna(row["rainfall_status"]) else "UNRECORDED_MISSING"

            telemetry_series.append({
                "timestamp": ts_str,
                "ankali_stage_m": a_val,
                "shigaon_stage_m": s_val,
                "koyna_stage_m": k_val,
                "rainfall_mm": r_val,
                "rainfall_status": r_stat,
                "ankali_avail": a_val is not None,
                "shigaon_avail": s_val is not None,
                "koyna_avail": k_val is not None,
                "rainfall_avail": r_stat != "UNRECORDED_MISSING" and r_val is not None
            })

        response_dict = {
            **prediction,
            "filename": filename,
            "selected_timestamp": selected_timestamp,
            "telemetry_series": telemetry_series,
            "features_engineered": {k: (round(v, 4) if v is not None and not pd.isna(v) else None) for k, v in features.items()}
        }

        return response_dict

