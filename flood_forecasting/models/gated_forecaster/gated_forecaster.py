"""
LAST_SIGNAL_AI: Gated Dual-Regime River-Level Forecaster

This module implements a hydrologically-aware hybrid forecaster that dynamically
switches between:
1. BASEFLOW Regime: Local stage Persistence (river_lag_1h) - low-variance optimal baseline.
2. SURGE Regime: Multi-Station Ridge Regression (Config C) - upstream-informed dynamic model.
3. DEGRADED Regime: Fallback to Persistence if local Ankali stage is available; NaN if missing.

Hysteresis smoothing prevents rapid oscillation at hydrograph crests.
"""

import os
import json
import joblib
import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple, Union
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score


class GatedDualRegimeForecaster:
    """
    Gated Dual-Regime Forecaster for Ankali Bridge river water level.
    """

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the forecaster with configuration and pre-trained models.
        """
        # Determine config path
        if config_path is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            config_path = os.path.join(base_dir, "regime_config.json")
            
        with open(config_path, "r") as f:
            self.config = json.load(f)
            
        self.thresholds = self.config["thresholds"]
        self.holding_hours = self.config["hysteresis"]["holding_hours"]
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
        
        self.state_counter = 0

    def detect_regimes(self, df: pd.DataFrame, reset_state: bool = True) -> pd.DataFrame:
        """
        Detect hydrological regimes sequentially across the input DataFrame.
        Input df must be sorted chronologically by timestamp.
        
        Returns DataFrame with 'regime' and 'regime_reason' columns.
        """
        if reset_state:
            self.state_counter = 0
            
        regimes = []
        reasons = []
        
        r_th = self.thresholds["rain_sum_72h_mm"]
        int_th = self.thresholds["rain_intensity_6h_mm_per_h"]
        s6_th = self.thresholds["shigaon_delta_6h_m"]
        s24_th = self.thresholds["shigaon_delta_24h_m"]
        k24_th = self.thresholds["koyna_delta_24h_m"]
        
        for _, row in df.iterrows():
            # 1. Local gauge availability check
            if pd.isna(row.get("river_lag_1h")):
                regimes.append("DEGRADED_UNUSABLE")
                reasons.append("Missing Ankali stage")
                self.state_counter = 0
                continue
                
            # 2. Upstream telemetry availability check
            missing_upstream = [f for f in self.features_schema if pd.isna(row.get(f))]
            if missing_upstream:
                regimes.append("DEGRADED")
                reasons.append(f"Missing upstream features: {','.join(missing_upstream[:3])}")
                self.state_counter = 0
                continue
                
            # 3. Check physical surge trigger conditions
            trig_rain = (row["rain_sum_72h"] > r_th) or (row["rain_intensity_6h"] > int_th)
            trig_shigaon = (row["shigaon_delta_6h"] > s6_th) or (row["shigaon_delta_24h"] > s24_th)
            trig_koyna = (row["koyna_delta_24h"] > k24_th)
            
            if trig_rain or trig_shigaon or trig_koyna:
                self.state_counter = self.holding_hours
                regimes.append("SURGE")
                triggers = []
                if trig_rain: triggers.append("rainfall_surge")
                if trig_shigaon: triggers.append("warna_stage_rise")
                if trig_koyna: triggers.append("koyna_dam_surge")
                reasons.append("+".join(triggers))
            elif self.state_counter > 0:
                self.state_counter -= 1
                regimes.append("SURGE")
                reasons.append(f"Hysteresis hold ({self.state_counter}h remaining)")
            else:
                regimes.append("BASEFLOW")
                reasons.append("Quiescent hydrological conditions")
                
        result_df = pd.DataFrame({
            "regime": regimes,
            "regime_reason": reasons
        }, index=df.index)
        
        return result_df

    def predict_horizon(self, df: pd.DataFrame, horizon: int = 24, reset_state: bool = True) -> pd.Series:
        """
        Generate river water level forecast for the specified horizon (+6h or +24h).
        Handles Baseflow, Surge, and Degraded regimes.
        """
        if horizon not in self.models:
            raise ValueError(f"Unsupported horizon: {horizon}. Must be 6 or 24.")
            
        regimes_df = self.detect_regimes(df, reset_state=reset_state)
        regimes = regimes_df["regime"]
        
        # Initialize predictions series
        predictions = pd.Series(index=df.index, dtype=float)
        
        # 1. Baseflow -> Persistence (river_lag_1h)
        baseflow_mask = regimes == "BASEFLOW"
        if baseflow_mask.any():
            predictions.loc[baseflow_mask] = df.loc[baseflow_mask, "river_lag_1h"]
            
        # 2. Surge -> Ridge Regression
        surge_mask = regimes == "SURGE"
        if surge_mask.any():
            X_surge = df.loc[surge_mask, self.features_schema]
            predictions.loc[surge_mask] = self.models[horizon].predict(X_surge)
            
        # 3. Degraded -> Fallback Persistence if river_lag_1h is available
        degraded_mask = regimes == "DEGRADED"
        if degraded_mask.any():
            predictions.loc[degraded_mask] = df.loc[degraded_mask, "river_lag_1h"]
            
        # 4. Degraded Unusable -> NaN
        unusable_mask = regimes == "DEGRADED_UNUSABLE"
        if unusable_mask.any():
            predictions.loc[unusable_mask] = np.nan
            
        return predictions

    def predict_all(self, df: pd.DataFrame, reset_state: bool = True) -> pd.DataFrame:
        """
        Predict both +6h and +24h horizons along with regime state.
        """
        regimes_df = self.detect_regimes(df, reset_state=reset_state)
        pred_6h = self.predict_horizon(df, horizon=6, reset_state=reset_state)
        pred_24h = self.predict_horizon(df, horizon=24, reset_state=reset_state)
        
        out = pd.DataFrame({
            "timestamp": df["timestamp"] if "timestamp" in df.columns else df.index,
            "regime": regimes_df["regime"],
            "regime_reason": regimes_df["regime_reason"],
            "pred_gated_plus_6h": pred_6h,
            "pred_gated_plus_24h": pred_24h
        }, index=df.index)
        
        return out

    def evaluate(self, df: pd.DataFrame, horizon: int = 24, target_col: Optional[str] = None) -> Dict[str, float]:
        """
        Evaluate forecaster on provided DataFrame with actual targets.
        """
        if target_col is None:
            target_col = f"target_river_plus_{horizon}h"
            
        preds = self.predict_horizon(df, horizon=horizon)
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
    print("Testing GatedDualRegimeForecaster class instantiation...")
    forecaster = GatedDualRegimeForecaster()
    print("Forecaster successfully initialized!")
    print(f"Features: {len(forecaster.features_schema)}")
    print(f"Thresholds: {forecaster.thresholds}")
    print(f"Holding hours: {forecaster.holding_hours}")

