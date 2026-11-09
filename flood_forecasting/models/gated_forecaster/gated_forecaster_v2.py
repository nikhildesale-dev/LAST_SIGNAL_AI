"""
LAST_SIGNAL_AI: Gated Dual-Regime River-Level Forecaster (Version 2.0 - Hardened)

Operational Reliability and Sensor-Failure Hardened Edition.

Key Enhancements over Version 1.0:
1. Target Gauge Health Monitor:
   - Detects MISSING, STALE, SUSPECT_STALE, and HEALTHY sensor states.
   - Evaluates consecutive identical measurements, rolling variability, and telemetry latency.
   - Withholds numerical forecast (DEGRADED_UNUSABLE) on STALE or MISSING target gauge.
   - Issues explicit uncertainty warning on SUSPECT_STALE with documented conservative policy.
2. Timestamp-Based Surge-Hold State Management:
   - Replaces integer counter with `last_surge_trigger_timestamp`.
   - Prevents missing hourly telemetry packets from prematurely clearing active surge holds.
   - Handles multi-hour dropouts gracefully: surge expires naturally if dropout > holding duration.
3. Corroborated Hydrological Surge Logic:
   - Calibrated exclusively on training data.
   - Requires upstream stage corroboration or extreme rainfall before activating surge mode.
   - Eliminates false surge triggers during unseasonal dry-season storms on depleted catchment soils.
"""

import os
import json
import joblib
import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple, Union
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score


class GatedDualRegimeForecasterV2:
    """
    Hardened Gated Dual-Regime Forecaster for Ankali Bridge river water level.
    """

    # Explicit Target Sensor Health Statuses
    STATUS_HEALTHY = "HEALTHY"
    STATUS_SUSPECT_STALE = "SUSPECT_STALE"
    STATUS_STALE = "STALE"
    STATUS_MISSING = "MISSING"

    # Operational Dispatch Regimes
    REGIME_BASEFLOW = "BASEFLOW"
    REGIME_SURGE = "SURGE"
    REGIME_DEGRADED_BASEFLOW = "DEGRADED_BASEFLOW"
    REGIME_DEGRADED_SURGE_FALLBACK = "DEGRADED_SURGE_FALLBACK"
    REGIME_DEGRADED_UNUSABLE = "DEGRADED_UNUSABLE"

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the forecaster with configuration and pre-trained models.
        """
        if config_path is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            config_path = os.path.join(base_dir, "regime_config.json")
            
        with open(config_path, "r") as f:
            self.config = json.load(f)
            
        self.thresholds = self.config["thresholds"]
        self.holding_duration = pd.Timedelta(hours=self.config["hysteresis"]["holding_hours"])
        self.features_schema = self.config["features_schema"]
        
        # Resolve model paths relative to repo root if needed
        repo_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
        
        path_6h = self.config["model_paths"]["ridge_6h"]
        if not os.path.isabs(path_6h):
            path_6h = os.path.join(repo_root, path_6h)
            
        path_24h = self.config["model_paths"]["ridge_24h"]
        if not os.path.isabs(path_24h):
            path_24h = os.path.join(repo_root, path_24h)
            
        self.models = {
            6: joblib.load(path_6h),
            24: joblib.load(path_24h)
        }
        
        # Timestamp-based state management
        self.last_surge_trigger_timestamp: Optional[pd.Timestamp] = None

    def assess_target_sensor_health(
        self,
        current_val: Optional[float],
        current_time: pd.Timestamp,
        history_vals: List[float],
        history_times: List[pd.Timestamp]
    ) -> Tuple[str, str]:
        """
        Evaluate health status of the target river gauge (Ankali Bridge).
        
        Returns:
            (sensor_status, status_reason)
        """
        # 1. Missing check
        if current_val is None or pd.isna(current_val):
            return self.STATUS_MISSING, "Observation is NaN / missing"
            
        # 2. Telemetry latency check (if previous timestamp is available)
        if len(history_times) > 0 and history_times[-1] is not None:
            time_gap = (current_time - history_times[-1]).total_seconds() / 3600.0
            if time_gap > 3.0:
                return self.STATUS_STALE, f"Telemetry gap of {time_gap:.1f}h exceeds 3h stale cutoff"
            elif time_gap > 1.5:
                return self.STATUS_SUSPECT_STALE, f"Telemetry latency of {time_gap:.1f}h exceeds expected 1h interval"

        # 3. Consecutive identical measurement check
        # Count consecutive identical float values
        consecutive_same = 1
        for val in reversed(history_vals):
            if val is not None and not pd.isna(val) and abs(val - current_val) < 1e-5:
                consecutive_same += 1
            else:
                break
                
        if consecutive_same >= 24:
            # 24+ consecutive hours of identical millimeter float values in open river
            return self.STATUS_STALE, f"Sensor flatlined: {consecutive_same} consecutive identical hourly readings ({current_val:.3f}m)"
        elif consecutive_same >= 12:
            # 12 to 23 hours: Could be low-flow night plateau, but warrants uncertainty flag
            return self.STATUS_SUSPECT_STALE, f"Prolonged invariant reading: {consecutive_same} identical hours ({current_val:.3f}m)"
            
        return self.STATUS_HEALTHY, "Sensor active with regular variance"

    def evaluate_operational_status(
        self,
        df: pd.DataFrame,
        reset_state: bool = True
    ) -> pd.DataFrame:
        """
        Full sequential operational diagnostic across the input DataFrame.
        Evaluates sensor health, physical triggers, timestamp-based hysteresis,
        and operational dispatch regime.
        """
        if reset_state:
            self.last_surge_trigger_timestamp = None
            
        # Ensure chronological ordering
        eval_df = df.copy()
        if "timestamp" in eval_df.columns:
            eval_df["timestamp"] = pd.to_datetime(eval_df["timestamp"])
            eval_df = eval_df.sort_values("timestamp")
        else:
            eval_df["timestamp"] = pd.date_range("2022-01-01", periods=len(eval_df), freq="1h")

        sensor_statuses = []
        sensor_reasons = []
        regimes = []
        regime_reasons = []
        dispatch_actions = []
        
        # Frozen thresholds
        r_th = self.thresholds["rain_sum_72h_mm"]
        int_th = self.thresholds["rain_intensity_6h_mm_per_h"]
        s6_th = self.thresholds["shigaon_delta_6h_m"]
        s24_th = self.thresholds["shigaon_delta_24h_m"]
        k24_th = self.thresholds["koyna_delta_24h_m"]
        
        history_vals: List[float] = []
        history_times: List[pd.Timestamp] = []
        
        for _, row in eval_df.iterrows():
            t_now = row["timestamp"]
            v_now = row.get("river_lag_1h", np.nan)
            
            # --- STEP 1: TARGET SENSOR HEALTH ASSESSMENT ---
            health_status, health_msg = self.assess_target_sensor_health(
                current_val=v_now,
                current_time=t_now,
                history_vals=history_vals,
                history_times=history_times
            )
            sensor_statuses.append(health_status)
            sensor_reasons.append(health_msg)
            
            # Update history cache (rolling window up to 48h)
            history_vals.append(v_now)
            history_times.append(t_now)
            if len(history_vals) > 48:
                history_vals.pop(0)
                history_times.pop(0)
                
            # --- STEP 2: CHECK PHYSICAL SURGE TRIGGERS ---
            # Corroborated trigger logic calibrated on training data
            trig_hydraulic = False
            trig_rainfall = False
            active_triggers = []
            
            # Upstream hydraulic stage surge
            s6_val = row.get("shigaon_delta_6h", np.nan)
            s24_val = row.get("shigaon_delta_24h", np.nan)
            k24_val = row.get("koyna_delta_24h", np.nan)
            
            if (pd.notna(s6_val) and s6_val > s6_th) or (pd.notna(s24_val) and s24_val > s24_th):
                trig_hydraulic = True
                active_triggers.append("warna_stage_rise")
                
            if pd.notna(k24_val) and k24_val > k24_th:
                trig_hydraulic = True
                active_triggers.append("koyna_dam_surge")
                
            # Rainfall surge: requires upstream corroboration OR extreme local rain
            rain72_val = row.get("rain_sum_72h", np.nan)
            int6_val = row.get("rain_intensity_6h", np.nan)
            
            has_rain = (pd.notna(rain72_val) and rain72_val > r_th) or (pd.notna(int6_val) and int6_val > int_th)
            if has_rain:
                # Corroboration: upstream river not falling OR Koyna not receding OR extreme rain > 25mm
                corroborated = (
                    (pd.notna(s6_val) and s6_val > 0.02) or
                    (pd.notna(k24_val) and k24_val >= 0.0) or
                    (pd.notna(rain72_val) and rain72_val > 25.0)
                )
                if corroborated:
                    trig_rainfall = True
                    active_triggers.append("corroborated_rainfall_surge")
                    
            is_new_surge_trigger = trig_hydraulic or trig_rainfall
            
            # --- STEP 3: TIMESTAMP-BASED HYSTERESIS MANAGEMENT ---
            if is_new_surge_trigger:
                self.last_surge_trigger_timestamp = t_now
                regime = self.REGIME_SURGE
                regime_msg = f"Surge trigger active ({'+'.join(active_triggers)})"
            elif self.last_surge_trigger_timestamp is not None:
                elapsed = t_now - self.last_surge_trigger_timestamp
                if elapsed <= self.holding_duration and elapsed >= pd.Timedelta(0):
                    rem_h = (self.holding_duration - elapsed).total_seconds() / 3600.0
                    regime = self.REGIME_SURGE
                    regime_msg = f"Hysteresis hold ({rem_h:.1f}h remaining from {self.last_surge_trigger_timestamp})"
                else:
                    regime = self.REGIME_BASEFLOW
                    regime_msg = "Quiescent hydrological conditions (hold expired)"
            else:
                regime = self.REGIME_BASEFLOW
                regime_msg = "Quiescent hydrological conditions"
                
            regimes.append(regime)
            regime_reasons.append(regime_msg)
            
            # --- STEP 4: OPERATIONAL DISPATCH ACTION ---
            if health_status in [self.STATUS_MISSING, self.STATUS_STALE]:
                action = self.REGIME_DEGRADED_UNUSABLE
            elif health_status == self.STATUS_SUSPECT_STALE:
                # Conservative documented policy: issue persistence with uncertainty warning
                action = "SUSPECT_STALE_CONSERVATIVE_PERSISTENCE"
            else:
                # Target is HEALTHY. Check upstream feature availability
                missing_up = [f for f in self.features_schema if pd.isna(row.get(f))]
                if missing_up:
                    if regime == self.REGIME_SURGE:
                        action = self.REGIME_DEGRADED_SURGE_FALLBACK
                    else:
                        action = self.REGIME_DEGRADED_BASEFLOW
                else:
                    if regime == self.REGIME_SURGE:
                        action = self.REGIME_SURGE
                    else:
                        action = self.REGIME_BASEFLOW
                        
            dispatch_actions.append(action)

        out_df = pd.DataFrame({
            "timestamp": eval_df["timestamp"],
            "target_sensor_status": sensor_statuses,
            "target_sensor_reason": sensor_reasons,
            "hydrological_regime": regimes,
            "regime_reason": regime_reasons,
            "dispatch_action": dispatch_actions
        }, index=eval_df.index)
        
        return out_df

    def predict_horizon(
        self,
        df: pd.DataFrame,
        horizon: int = 24,
        reset_state: bool = True
    ) -> pd.DataFrame:
        """
        Generate river water level forecast for horizon (+6h or +24h) with explicit
        sensor health, dispatch mode, and uncertainty tracking.
        """
        if horizon not in self.models:
            raise ValueError(f"Unsupported horizon: {horizon}. Must be 6 or 24.")
            
        # Ensure clean integer indexing to prevent duplicated index collisions
        clean_df = df.reset_index(drop=True).copy()
        diag_df = self.evaluate_operational_status(clean_df, reset_state=reset_state)
        
        forecasts = pd.Series(index=clean_df.index, dtype=float)
        uncertainty_flags = []
        fallback_indicators = []
        
        for i in range(len(clean_df)):
            row_diag = diag_df.iloc[i]
            action = row_diag["dispatch_action"]
            row_data = clean_df.iloc[i]
            
            if action == self.REGIME_DEGRADED_UNUSABLE:
                forecasts.iloc[i] = np.nan
                uncertainty_flags.append("HIGH_ALERT_FORECAST_WITHHELD")
                fallback_indicators.append("NO_FORECAST_SENSOR_STALE_OR_MISSING")
                
            elif action == "SUSPECT_STALE_CONSERVATIVE_PERSISTENCE":
                forecasts.iloc[i] = row_data["river_lag_1h"]
                uncertainty_flags.append("WARNING_PROLONGED_CONSTANT_STAGE")
                fallback_indicators.append("PERSISTENCE_SUSPECT_STALE")
                
            elif action == self.REGIME_BASEFLOW:
                forecasts.iloc[i] = row_data["river_lag_1h"]
                uncertainty_flags.append("NOMINAL")
                fallback_indicators.append("NONE_BASEFLOW_PERSISTENCE")
                
            elif action == self.REGIME_DEGRADED_BASEFLOW:
                forecasts.iloc[i] = row_data["river_lag_1h"]
                uncertainty_flags.append("NOMINAL")
                fallback_indicators.append("UPSTREAM_MISSING_BASEFLOW_PERSISTENCE")
                
            elif action == self.REGIME_DEGRADED_SURGE_FALLBACK:
                forecasts.iloc[i] = row_data["river_lag_1h"]
                uncertainty_flags.append("SURGE_DEGRADED_BY_UPSTREAM_OUTAGE")
                fallback_indicators.append("FALLBACK_TO_PERSISTENCE_DUE_TO_UPSTREAM_NAN")
                
            elif action == self.REGIME_SURGE:
                feat_vec = pd.DataFrame([row_data[self.features_schema].to_dict()])
                forecasts.iloc[i] = self.models[horizon].predict(feat_vec)[0]
                uncertainty_flags.append("NOMINAL_SURGE_RIDGE")
                fallback_indicators.append("NONE_ACTIVE_RIDGE_PREDICTION")
                
        diag_df[f"forecast_plus_{horizon}h"] = forecasts
        diag_df["uncertainty_status"] = uncertainty_flags
        diag_df["fallback_status"] = fallback_indicators
        
        # Restore original index
        diag_df.index = df.index
        return diag_df

    def evaluate(
        self,
        df: pd.DataFrame,
        horizon: int = 24,
        target_col: Optional[str] = None
    ) -> Dict[str, float]:
        """
        Evaluate forecaster on provided DataFrame with actual targets.
        """
        if target_col is None:
            target_col = f"target_river_plus_{horizon}h"
            
        res_df = self.predict_horizon(df, horizon=horizon)
        preds = res_df[f"forecast_plus_{horizon}h"]
        valid = df[target_col].notna() & preds.notna()
        
        y_true = df.loc[valid, target_col]
        y_pred = preds.loc[valid]
        
        return {
            "samples": int(len(y_true)),
            "mae": float(mean_absolute_error(y_true, y_pred)),
            "rmse": float(np.sqrt(mean_squared_error(y_true, y_pred))),
            "r2": float(r2_score(y_true, y_pred))
        }


if __name__ == "__main__":
    print("Testing GatedDualRegimeForecasterV2 class instantiation...")
    v2 = GatedDualRegimeForecasterV2()
    print("GatedDualRegimeForecasterV2 initialized successfully!")
    print(f"Holding duration: {v2.holding_duration}")
    print(f"Features schema: {len(v2.features_schema)} features")
