"""
LAST_SIGNAL_AI: High-Level River-Level Forecaster Engine

Integrates sensor health monitoring, hydrological regime detection,
causal feature engineering, and pre-trained serialized model pipelines.
"""

import os
import json
import joblib
from typing import Any, Dict, List, Optional, Tuple, Union
import pandas as pd
import numpy as np

from .features import FeatureEngineer, FEATURES_SCHEMA
from .sensor_health import SensorHealthMonitor, SensorStatus
from .regime_detection import RegimeDetector, HydrologicalRegime


class RiverLevelForecaster:
    """
    Operational forecaster exposing verified dual-regime predictions for Ankali Bridge.
    """

    def __init__(self, models_dir: Optional[str] = None, config_path: Optional[str] = None):
        """
        Load serialized model artifacts and configure threshold parameters.
        """
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        
        if config_path is None:
            config_path = os.path.join(repo_root, "models", "gated_forecaster", "regime_config.json")
            
        with open(config_path, "r") as f:
            self.config = json.load(f)
            
        if models_dir is None:
            models_dir = os.path.join(repo_root, "models", "multistation")
            
        path_6h = os.path.join(models_dir, "config_c_ridge_6h.joblib")
        path_24h = os.path.join(models_dir, "config_c_ridge_24h.joblib")
        
        if not os.path.exists(path_6h) or not os.path.exists(path_24h):
            raise FileNotFoundError(f"Serialized models not found in {models_dir}. Check paths.")
            
        self.models = {
            6: joblib.load(path_6h),
            24: joblib.load(path_24h)
        }
        
        # Initialize component monitors
        self.health_monitor = SensorHealthMonitor(
            stale_hours_threshold=24,
            suspect_hours_threshold=12,
            max_latency_hours=3.0,
            expected_interval_hours=1.0
        )
        
        th = self.config["thresholds"]
        self.regime_detector = RegimeDetector(
            rain_sum_72h_threshold=th["rain_sum_72h_mm"],
            rain_intensity_threshold=th["rain_intensity_6h_mm_per_h"],
            shigaon_delta_6h_threshold=th["shigaon_delta_6h_m"],
            shigaon_delta_24h_threshold=th["shigaon_delta_24h_m"],
            koyna_delta_24h_threshold=th["koyna_delta_24h_m"],
            holding_hours=self.config["hysteresis"]["holding_hours"]
        )
        
        self.features_schema = FEATURES_SCHEMA

    def predict(
        self,
        current_stage_m: Optional[float],
        current_time: Union[str, pd.Timestamp],
        features: Dict[str, Union[float, int, None]],
        history_stages: Optional[List[float]] = None,
        history_timestamps: Optional[List[Union[str, pd.Timestamp]]] = None,
        history_shigaon_stages: Optional[List[float]] = None,
        history_shigaon_timestamps: Optional[List[Union[str, pd.Timestamp]]] = None,
        history_koyna_stages: Optional[List[float]] = None,
        history_koyna_timestamps: Optional[List[Union[str, pd.Timestamp]]] = None,
        shigaon_stage_m: Optional[float] = None,
        koyna_stage_m: Optional[float] = None,
        rainfall_measured_mm: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Execute full operational forecast pipeline.
        
        Args:
            current_stage_m: Current Ankali Bridge water level reading in meters.
            current_time: Observation timestamp.
            features: Dictionary containing required upstream and rainfall features.
            history_stages: List of previous consecutive hourly water level readings.
            history_timestamps: List of previous consecutive observation timestamps.
            history_shigaon_stages: List of previous consecutive stage readings for Shigaon.
            history_shigaon_timestamps: List of observation timestamps for Shigaon.
            history_koyna_stages: List of previous consecutive stage readings for Koyna_1.
            history_koyna_timestamps: List of observation timestamps for Koyna_1.
            shigaon_stage_m: Current or latest stage reading for Shigaon.
            koyna_stage_m: Current or latest stage reading for Koyna_1.
            
        Returns:
            Structured dictionary with forecast values and operational diagnostics.
        """
        # Parse timestamp
        t_now = pd.to_datetime(current_time)
        h_times = [pd.to_datetime(t) for t in history_timestamps] if history_timestamps else []
        h_vals = history_stages or []
        
        # 1. Target sensor health assessment
        sensor_status, sensor_reason, is_safe = self.health_monitor.assess_target_sensor(
            current_val=current_stage_m,
            current_time=t_now,
            history_vals=h_vals,
            history_times=h_times
        )

        rain_measured = rainfall_measured_mm if rainfall_measured_mm is not None else features.get("rainfall_measured_mm")
        feature_statuses = self._determine_feature_statuses(features, h_vals, h_times, rain_measured=rain_measured)
        
        # 2. Upstream sensor health assessment (Shigaon & Koyna_1)
        shigaon_deltas = {k: features.get(k) for k in ["shigaon_delta_1h", "shigaon_delta_3h", "shigaon_delta_6h", "shigaon_delta_24h"]}
        s_val = shigaon_stage_m
        if s_val is None and history_shigaon_stages and len(history_shigaon_stages) > 0:
            s_val = history_shigaon_stages[-1]
            
        shigaon_status, shigaon_reason, shigaon_reliable = self.health_monitor.assess_upstream_sensor(
            station_name="Shigaon",
            current_val=s_val,
            current_time=t_now,
            history_vals=history_shigaon_stages,
            history_times=history_shigaon_timestamps,
            deltas=shigaon_deltas,
            corroborating_rain=features.get("rain_sum_24h")
        )

        koyna_deltas = {k: features.get(k) for k in ["koyna_delta_1h", "koyna_delta_3h", "koyna_delta_6h", "koyna_delta_24h"]}
        k_val = koyna_stage_m
        if k_val is None and history_koyna_stages and len(history_koyna_stages) > 0:
            k_val = history_koyna_stages[-1]
            
        koyna_status, koyna_reason, koyna_reliable = self.health_monitor.assess_upstream_sensor(
            station_name="Koyna_1",
            current_val=k_val,
            current_time=t_now,
            history_vals=history_koyna_stages,
            history_times=history_koyna_timestamps,
            deltas=koyna_deltas,
            corroborating_rain=features.get("rain_sum_24h")
        )

        # Rainfall semantics check
        rain_sum = features.get("rain_sum_24h")
        rain_cols = ["rain_sum_24h", "rain_sum_48h", "rain_sum_72h", "rain_intensity_6h"]
        has_rain_features = any(features.get(c) is not None and pd.notna(features.get(c)) for c in rain_cols)
        
        if rain_measured is not None and pd.notna(rain_measured):
            rain_status = "MEASURED_POSITIVE" if float(rain_measured) > 0.0 else "MEASURED_ZERO"
        elif rain_sum is not None and pd.notna(rain_sum):
            rain_status = "ASSUMED_ZERO" if float(rain_sum) == 0.0 else "MEASURED_POSITIVE"
        elif has_rain_features:
            rain_status = "ASSUMED_ZERO"
        else:
            rain_status = "UNRECORDED_MISSING"

        upstream_health = {
            "shigaon_gauge": shigaon_status.value,
            "koyna_1_gauge": koyna_status.value,
            "sangli_rainfall": rain_status
        }

        upstream_avail = {
            "shigaon_gauge": bool(shigaon_reliable),
            "koyna_1_gauge": bool(koyna_reliable),
            "sangli_rainfall": bool(has_rain_features and rain_status != "UNRECORDED_MISSING")
        }

        # If target sensor is STALE or MISSING, withhold numerical forecast completely
        if not is_safe:
            return {
                "prediction_available": False,
                "forecast_plus_6h": None,
                "forecast_plus_24h": None,
                "current_river_level_m": current_stage_m,
                "hydrological_regime": HydrologicalRegime.DEGRADED_UNUSABLE.value,
                "target_sensor_health": sensor_status.value,
                "upstream_sensor_availability": upstream_avail,
                "upstream_sensor_health": upstream_health,
                "feature_statuses": feature_statuses,
                "fallback_reason": f"Forecast withheld: target sensor is {sensor_status.value} ({sensor_reason})",
                "prediction_timestamp": str(t_now),
                "uncertainty_warning": "CRITICAL_SENSOR_FAULT_FORECAST_WITHHELD"
            }
            
        all_upstream_intact = all(upstream_avail.values())
        has_all_model_features = all(features.get(c) is not None and pd.notna(features.get(c)) for c in FEATURES_SCHEMA)
        all_features_intact = all_upstream_intact and has_all_model_features
        
        # 3. Detect hydrological regime
        regime, regime_reason, is_holding = self.regime_detector.evaluate_step(
            features=features,
            current_time=t_now
        )
        
        # 4. Generate forecasts based on regime and telemetry state
        forecast_6h = None
        forecast_24h = None
        fallback_msg = None
        uncertainty_msg = "NOMINAL"
        regime_str = regime.value if hasattr(regime, "value") else str(regime)
        
        if sensor_status == SensorStatus.SUSPECT_STALE:
            uncertainty_msg = f"WARNING_PROLONGED_CONSTANT_STAGE ({sensor_reason})"

        # Check if upstream flatline is suspected
        has_upstream_suspect = (
            shigaon_status in [SensorStatus.SUSPECT_FLATLINE, SensorStatus.STALE] or
            koyna_status in [SensorStatus.SUSPECT_FLATLINE, SensorStatus.STALE]
        )

        if regime == HydrologicalRegime.SURGE and all_features_intact:
            # Full multi-station Ridge prediction
            feat_df = FeatureEngineer.assemble_features_dataframe(features)
            forecast_6h = float(self.models[6].predict(feat_df)[0])
            forecast_24h = float(self.models[24].predict(feat_df)[0])
            uncertainty_msg = "NOMINAL_SURGE_RIDGE"
            
        elif regime == HydrologicalRegime.SURGE and not all_features_intact:
            # Active surge, but upstream features missing/suspect -> safe persistence fallback
            forecast_6h = float(current_stage_m) if current_stage_m is not None else None
            forecast_24h = float(current_stage_m) if current_stage_m is not None else None
            fallback_msg = "Upstream telemetry missing or suspect during active surge; fallback to persistence"
            uncertainty_msg = "SURGE_DEGRADED_BY_UPSTREAM_OUTAGE"
            
        elif regime == HydrologicalRegime.BASEFLOW:
            forecast_6h = float(current_stage_m) if current_stage_m is not None else None
            forecast_24h = float(current_stage_m) if current_stage_m is not None else None
            
            if has_upstream_suspect:
                # Upstream zero movement cannot confirm baseflow
                suspect_info = []
                if shigaon_status in [SensorStatus.SUSPECT_FLATLINE, SensorStatus.STALE]:
                    suspect_info.append(f"Shigaon ({shigaon_status.value})")
                if koyna_status in [SensorStatus.SUSPECT_FLATLINE, SensorStatus.STALE]:
                    suspect_info.append(f"Koyna_1 ({koyna_status.value})")
                suspect_label = ", ".join(suspect_info)
                
                regime_str = "DEGRADED"
                fallback_msg = f"Upstream gauge {suspect_label}: zero movement cannot confirm baseflow; conservative persistence dispatched with degraded reliability"
                if sensor_status == SensorStatus.SUSPECT_STALE:
                    uncertainty_msg = f"WARNING_PROLONGED_CONSTANT_STAGE; UPSTREAM_SENSOR_{shigaon_status.value if not shigaon_reliable else koyna_status.value}"
                else:
                    uncertainty_msg = f"UPSTREAM_SENSOR_{shigaon_status.value if not shigaon_reliable else koyna_status.value}"
            else:
                fallback_msg = "Normal baseflow operation (Persistence dispatched)"
                if not all_features_intact:
                    fallback_msg += " [Upstream telemetry partial outage]"
                    if sensor_status == SensorStatus.HEALTHY:
                        uncertainty_msg = "UPSTREAM_TELEMETRY_DEGRADED"
                
        return {
            "prediction_available": True,
            "forecast_plus_6h": round(forecast_6h, 4) if forecast_6h is not None else None,
            "forecast_plus_24h": round(forecast_24h, 4) if forecast_24h is not None else None,
            "current_river_level_m": round(current_stage_m, 4) if current_stage_m is not None else None,
            "hydrological_regime": regime_str,
            "target_sensor_health": sensor_status.value,
            "upstream_sensor_availability": upstream_avail,
            "upstream_sensor_health": upstream_health,
            "feature_statuses": feature_statuses,
            "fallback_reason": fallback_msg,
            "prediction_timestamp": str(t_now),
            "uncertainty_warning": uncertainty_msg
        }

    def _determine_feature_statuses(
        self,
        features: Dict[str, Any],
        history_stages: Optional[List[float]],
        history_timestamps: Optional[List[str]],
        rain_measured: Optional[float] = None
    ) -> Dict[str, str]:
        """
        Categorize each feature into display availability statuses:
        - OK: directly available from valid telemetry
        - TELEMETRY_DROPOUT: physical station outage / sensor transmission failure
        - INSUFFICIENT_HISTORY: window lookback history < required feature lead time
        - ZERO_IMPUTED: dry weather zero-imputation under IMD meteorological convention
        - MISSING: completely unobserved / undefined
        """
        statuses: Dict[str, str] = {}
        hist_len = len(history_stages) if history_stages is not None else 0

        shigaon_cols = ["shigaon_delta_1h", "shigaon_delta_3h", "shigaon_delta_6h", "shigaon_delta_24h"]
        koyna_cols = ["koyna_delta_1h", "koyna_delta_3h", "koyna_delta_6h", "koyna_delta_24h"]
        rain_cols = ["rain_sum_24h", "rain_sum_48h", "rain_sum_72h", "rain_intensity_6h"]

        has_shigaon = any(features.get(c) is not None and pd.notna(features.get(c)) for c in shigaon_cols)
        has_koyna = any(features.get(c) is not None and pd.notna(features.get(c)) for c in koyna_cols)
        has_rain = any(features.get(c) is not None and pd.notna(features.get(c)) for c in rain_cols)

        # 1. River lags
        val_1 = features.get("river_lag_1h")
        if val_1 is not None and pd.notna(val_1):
            statuses["river_lag_1h"] = "OK"
        elif hist_len < 1:
            statuses["river_lag_1h"] = "INSUFFICIENT_HISTORY"
        else:
            statuses["river_lag_1h"] = "TELEMETRY_DROPOUT"

        val_6 = features.get("river_lag_6h")
        if val_6 is not None and pd.notna(val_6):
            statuses["river_lag_6h"] = "OK"
        elif hist_len < 6:
            statuses["river_lag_6h"] = "INSUFFICIENT_HISTORY"
        else:
            statuses["river_lag_6h"] = "TELEMETRY_DROPOUT"

        val_24 = features.get("river_lag_24h")
        if val_24 is not None and pd.notna(val_24):
            statuses["river_lag_24h"] = "OK"
        elif hist_len < 24:
            statuses["river_lag_24h"] = "INSUFFICIENT_HISTORY"
        else:
            statuses["river_lag_24h"] = "TELEMETRY_DROPOUT"

        # 2. Shigaon deltas
        shigaon_req = {
            "shigaon_delta_1h": 2,
            "shigaon_delta_3h": 4,
            "shigaon_delta_6h": 7,
            "shigaon_delta_24h": 25
        }
        for col, req_len in shigaon_req.items():
            val = features.get(col)
            if val is not None and pd.notna(val):
                statuses[col] = "OK"
            elif not has_shigaon:
                statuses[col] = "TELEMETRY_DROPOUT"
            elif hist_len < req_len:
                statuses[col] = "INSUFFICIENT_HISTORY"
            else:
                statuses[col] = "TELEMETRY_DROPOUT"

        # 3. Koyna deltas
        koyna_req = {
            "koyna_delta_1h": 2,
            "koyna_delta_3h": 4,
            "koyna_delta_6h": 7,
            "koyna_delta_24h": 25
        }
        for col, req_len in koyna_req.items():
            val = features.get(col)
            if val is not None and pd.notna(val):
                statuses[col] = "OK"
            elif not has_koyna:
                statuses[col] = "TELEMETRY_DROPOUT"
            elif hist_len < req_len:
                statuses[col] = "INSUFFICIENT_HISTORY"
            else:
                statuses[col] = "TELEMETRY_DROPOUT"

        # 4. Rainfall features
        rain_req = {
            "rain_intensity_6h": 6,
            "rain_sum_24h": 24,
            "rain_sum_48h": 48,
            "rain_sum_72h": 72
        }
        for col, req_len in rain_req.items():
            val = features.get(col)
            if val is not None and pd.notna(val):
                if float(val) == 0.0:
                    if rain_measured is not None and float(rain_measured) == 0.0:
                        statuses[col] = "MEASURED_ZERO"
                    else:
                        statuses[col] = "ASSUMED_ZERO"
                else:
                    statuses[col] = "OK"
            elif hist_len < req_len:
                statuses[col] = "INSUFFICIENT_HISTORY"
            elif not has_rain:
                statuses[col] = "TELEMETRY_DROPOUT"
            else:
                statuses[col] = "MISSING"

        return statuses

    def _check_upstream_availability(self, features: Dict[str, Any]) -> Dict[str, bool]:
        """Verify availability of individual telemetry stations."""
        shigaon_cols = ["shigaon_delta_1h", "shigaon_delta_3h", "shigaon_delta_6h", "shigaon_delta_24h"]
        koyna_cols = ["koyna_delta_1h", "koyna_delta_3h", "koyna_delta_6h", "koyna_delta_24h"]
        rain_cols = ["rain_sum_24h", "rain_sum_48h", "rain_sum_72h", "rain_intensity_6h"]
        
        has_shigaon = all(features.get(c) is not None and pd.notna(features.get(c)) for c in shigaon_cols)
        has_koyna = all(features.get(c) is not None and pd.notna(features.get(c)) for c in koyna_cols)
        has_rain = all(features.get(c) is not None and pd.notna(features.get(c)) for c in rain_cols)
        
        return {
            "shigaon_gauge": bool(has_shigaon),
            "koyna_1_gauge": bool(has_koyna),
            "sangli_rainfall": bool(has_rain)
        }

