"""
LAST_SIGNAL_AI: Feature Engineering and Schema Enforcement Module

Implements causal feature engineering for multi-station hydrological forecasting:
1. Cumulative rainfall and intensity windows.
2. Target gauge river-level lags.
3. Upstream tributary stage change rates (Shigaon & Koyna_1).
"""

from typing import Dict, List, Optional, Union
import pandas as pd
import numpy as np

# Strict 15-feature schema required by serialized model pipelines (Config C)
FEATURES_SCHEMA: List[str] = [
    "rain_sum_24h",
    "rain_sum_48h",
    "rain_sum_72h",
    "rain_intensity_6h",
    "river_lag_1h",
    "river_lag_6h",
    "river_lag_24h",
    "shigaon_delta_1h",
    "shigaon_delta_3h",
    "shigaon_delta_6h",
    "shigaon_delta_24h",
    "koyna_delta_1h",
    "koyna_delta_3h",
    "koyna_delta_6h",
    "koyna_delta_24h"
]


class FeatureEngineer:
    """
    Feature engineering utility for online inference and offline batch pipelines.
    """

    @staticmethod
    def calculate_rainfall_features(rain_hourly: pd.Series) -> Dict[str, float]:
        """
        Calculate rolling rainfall metrics from an hourly series.
        Requires at least 72 hours of historical rainfall observations for full calculation.
        Preserves NaN when observations are missing rather than fabricating 0.0 mm.
        """
        def _safe_sum(s: pd.Series, window: int) -> float:
            if len(s) < window:
                return np.nan
            sub = s.tail(window)
            val = sub.sum(min_count=1)
            return float(val) if pd.notna(val) else np.nan

        def _safe_mean(s: pd.Series, window: int) -> float:
            if len(s) < window:
                return np.nan
            sub = s.tail(window)
            val = sub.mean()
            return float(val) if pd.notna(val) else np.nan

        rain_24 = _safe_sum(rain_hourly, 24)
        rain_48 = _safe_sum(rain_hourly, 48)
        rain_72 = _safe_sum(rain_hourly, 72)
        rain_int6 = _safe_mean(rain_hourly, 6)

        return {
            "rain_sum_24h": rain_24,
            "rain_sum_48h": rain_48,
            "rain_sum_72h": rain_72,
            "rain_intensity_6h": rain_int6
        }

    @staticmethod
    def calculate_river_lags(stage_hourly: pd.Series) -> Dict[str, float]:
        """
        Extract causal stage lags for Ankali Bridge.
        stage_hourly must be ordered sequentially [..., t-2, t-1].
        """
        if len(stage_hourly) < 1:
            return {"river_lag_1h": np.nan, "river_lag_6h": np.nan, "river_lag_24h": np.nan}
            
        lag_1h = float(stage_hourly.iloc[-1])
        lag_6h = float(stage_hourly.iloc[-6]) if len(stage_hourly) >= 6 else np.nan
        lag_24h = float(stage_hourly.iloc[-24]) if len(stage_hourly) >= 24 else np.nan
        
        return {
            "river_lag_1h": lag_1h,
            "river_lag_6h": lag_6h,
            "river_lag_24h": lag_24h
        }

    @staticmethod
    def calculate_stage_deltas(stage_hourly: pd.Series, prefix: str = "shigaon") -> Dict[str, float]:
        """
        Calculate upstream stage differences relative to t-1.
        delta_1h = stage(t-1) - stage(t-2)
        delta_3h = stage(t-1) - stage(t-4)
        delta_6h = stage(t-1) - stage(t-7)
        delta_24h = stage(t-1) - stage(t-25)
        """
        if len(stage_hourly) < 2:
            return {
                f"{prefix}_delta_1h": np.nan,
                f"{prefix}_delta_3h": np.nan,
                f"{prefix}_delta_6h": np.nan,
                f"{prefix}_delta_24h": np.nan
            }
            
        s_t1 = stage_hourly.iloc[-1]
        d1 = float(s_t1 - stage_hourly.iloc[-2]) if len(stage_hourly) >= 2 else np.nan
        d3 = float(s_t1 - stage_hourly.iloc[-4]) if len(stage_hourly) >= 4 else np.nan
        d6 = float(s_t1 - stage_hourly.iloc[-7]) if len(stage_hourly) >= 7 else np.nan
        d24 = float(s_t1 - stage_hourly.iloc[-25]) if len(stage_hourly) >= 25 else np.nan
        
        return {
            f"{prefix}_delta_1h": d1,
            f"{prefix}_delta_3h": d3,
            f"{prefix}_delta_6h": d6,
            f"{prefix}_delta_24h": d24
        }

    @classmethod
    def assemble_features_dataframe(cls, feature_dict: Dict[str, Union[float, int, None]]) -> pd.DataFrame:
        """
        Ensure feature vector matches exact 15-column schema and types required by sklearn pipeline.
        """
        row = {}
        for col in FEATURES_SCHEMA:
            val = feature_dict.get(col, np.nan)
            row[col] = float(val) if val is not None and not pd.isna(val) else np.nan
            
        return pd.DataFrame([row], columns=FEATURES_SCHEMA)

