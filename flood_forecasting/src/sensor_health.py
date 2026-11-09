"""
LAST_SIGNAL_AI: Sensor Health Monitoring and Telemetry Validation Module

Implements a four-tier operational health monitor for river stage sensors:
- HEALTHY: Normal operation and expected river dynamics.
- SUSPECT_STALE: Prolonged invariant readings (12-24h) or telemetry latency (1.5-3.0h).
- STALE: Flatlined sensor (>=24h invariant float) or communication failure (>3.0h).
- MISSING: Telemetry packet null or absent.
"""

from enum import Enum
from typing import Dict, List, Optional, Tuple, Union
import pandas as pd
import numpy as np


class SensorStatus(str, Enum):
    HEALTHY = "HEALTHY"
    STABLE_BUT_PLAUSIBLE = "STABLE_BUT_PLAUSIBLE"
    SUSPECT_FLATLINE = "SUSPECT_FLATLINE"
    SUSPECT_STALE = "SUSPECT_STALE"
    STALE = "STALE"
    MISSING = "MISSING"


class SensorHealthMonitor:
    """
    Sensor health validator for field telemetry streams.
    Supports both target gauge evaluation and upstream tributary/reservoir diagnostics.
    """

    def __init__(
        self,
        stale_hours_threshold: int = 24,
        suspect_hours_threshold: int = 12,
        max_latency_hours: float = 3.0,
        expected_interval_hours: float = 1.0,
        upstream_plausible_hours_threshold: float = 24.0,
        upstream_suspect_flatline_hours_threshold: float = 24.0,
        upstream_stale_hours_threshold: float = 72.0
    ):
        self.stale_hours_threshold = stale_hours_threshold
        self.suspect_hours_threshold = suspect_hours_threshold
        self.max_latency_hours = max_latency_hours
        self.expected_interval_hours = expected_interval_hours
        self.upstream_plausible_hours_threshold = upstream_plausible_hours_threshold
        self.upstream_suspect_flatline_hours_threshold = upstream_suspect_flatline_hours_threshold
        self.upstream_stale_hours_threshold = upstream_stale_hours_threshold

    def assess_target_sensor(
        self,
        current_val: Optional[float],
        current_time: Optional[pd.Timestamp] = None,
        history_vals: Optional[List[float]] = None,
        history_times: Optional[List[pd.Timestamp]] = None
    ) -> Tuple[SensorStatus, str, bool]:
        """
        Assess health of Ankali Bridge target river gauge.
        
        Returns:
            Tuple of:
                - SensorStatus (HEALTHY, SUSPECT_STALE, STALE, MISSING)
                - Diagnostic message explaining reason
                - is_forecast_safe (bool: False if numerical forecast must be withheld)
        """
        # 1. Missing check
        if current_val is None or pd.isna(current_val):
            return SensorStatus.MISSING, "Target gauge measurement is null / missing", False
            
        history_vals = history_vals or []
        history_times = history_times or []
        
        # 2. Telemetry latency / freshness check
        if current_time is not None and len(history_times) > 0 and history_times[-1] is not None:
            time_gap = (current_time - history_times[-1]).total_seconds() / 3600.0
            if time_gap > self.max_latency_hours:
                return (
                    SensorStatus.STALE,
                    f"Telemetry gap of {time_gap:.1f}h exceeds {self.max_latency_hours:.1f}h stale threshold",
                    False
                )
            elif time_gap > self.expected_interval_hours * 1.5:
                return (
                    SensorStatus.SUSPECT_STALE,
                    f"Telemetry latency of {time_gap:.1f}h exceeds expected {self.expected_interval_hours:.1f}h interval",
                    True # Conservative policy: permitted with alert
                )

        # 3. Invariant float measurement check (flatline detection)
        consecutive_same = 1
        for val in reversed(history_vals):
            if val is not None and not pd.isna(val) and abs(val - current_val) < 1e-5:
                consecutive_same += 1
            else:
                break
                
        if consecutive_same >= self.stale_hours_threshold:
            return (
                SensorStatus.STALE,
                f"Sensor flatlined: {consecutive_same} consecutive identical hourly readings ({current_val:.3f}m)",
                False # Must withhold numerical forecast
            )
        elif consecutive_same >= self.suspect_hours_threshold:
            return (
                SensorStatus.SUSPECT_STALE,
                f"Prolonged invariant reading: {consecutive_same} identical hours ({current_val:.3f}m)",
                True # Conservative persistence with alert
            )
            
        return SensorStatus.HEALTHY, "Sensor active with regular variance", True

    def assess_upstream_sensor(
        self,
        station_name: str,
        current_val: Optional[float],
        current_time: Optional[Union[pd.Timestamp, str]] = None,
        history_vals: Optional[List[float]] = None,
        history_times: Optional[List[Union[pd.Timestamp, str]]] = None,
        deltas: Optional[Dict[str, Optional[float]]] = None,
        corroborating_rain: Optional[float] = None
    ) -> Tuple[SensorStatus, str, bool]:
        """
        Assess health of upstream tributary or reservoir gauge (e.g. Shigaon, Koyna_1).
        
        Distinguishes:
        1. HEALTHY: Normal active variance, fresh communication.
        2. STABLE_BUT_PLAUSIBLE: Quiescent stage (<= 24.0h invariant or small delta) during natural baseflow.
        3. SUSPECT_FLATLINE: Invariant float for prolonged period (>= 24.0h and < 72.0h), or invariant despite rain.
        4. STALE: Telemetry latency > 3.0h OR invariant float >= 72.0h (persistent flatline).
        5. MISSING: Measurement packet null or unobserved.
        
        Returns:
            Tuple of:
                - SensorStatus
                - Diagnostic explanation message
                - is_reliable (bool: False if upstream zero movement cannot be trusted)
        """
        # 1. Missing check
        if current_val is None or pd.isna(current_val):
            if deltas and all(v is None or pd.isna(v) for v in deltas.values()):
                return SensorStatus.MISSING, f"{station_name} gauge telemetry is null / missing", False
            if deltas is None:
                return SensorStatus.MISSING, f"{station_name} gauge telemetry is null / missing", False

        t_now = pd.to_datetime(current_time) if current_time is not None else None
        
        clean_history_vals = [float(v) for v in history_vals if v is not None and pd.notna(v)] if history_vals else []
        clean_history_times = [pd.to_datetime(t) for t in history_times if t is not None and pd.notna(t)] if history_times else []

        # 2. Telemetry latency / freshness check
        if t_now is not None and len(clean_history_times) > 0:
            last_t = clean_history_times[-1]
            time_gap = (t_now - last_t).total_seconds() / 3600.0
            if time_gap > self.max_latency_hours:
                return (
                    SensorStatus.STALE,
                    f"{station_name} telemetry gap of {time_gap:.1f}h exceeds {self.max_latency_hours:.1f}h stale threshold",
                    False
                )

        # 3. Timestamp-based Invariant Reading (Flatline) Detection
        duration_hours = 0.0
        
        if t_now is not None and len(clean_history_vals) > 0 and len(clean_history_times) == len(clean_history_vals) and current_val is not None:
            oldest_invariant_time = t_now
            
            for v, t_obs in zip(reversed(clean_history_vals), reversed(clean_history_times)):
                if abs(v - current_val) < 1e-4:
                    oldest_invariant_time = t_obs
                else:
                    break
                    
            duration_hours = max(0.0, (t_now - oldest_invariant_time).total_seconds() / 3600.0)
            
        elif deltas is not None:
            # Fallback to feature deltas when historical series is not supplied
            valid_d = [v for v in deltas.values() if v is not None and pd.notna(v)]
            if len(valid_d) == 0:
                return SensorStatus.MISSING, f"{station_name} deltas missing", False
                
            all_zero = all(abs(v) < 1e-5 for v in valid_d)
            if all_zero and len(valid_d) >= 4:
                duration_hours = 24.0
            elif all_zero:
                duration_hours = 6.0
            elif any(abs(v) > 0.005 for v in valid_d):
                duration_hours = 0.0
            else:
                duration_hours = 3.0

        # Classify based on timestamp duration and meteorological context
        has_heavy_rain = (corroborating_rain is not None and pd.notna(corroborating_rain) and corroborating_rain > 10.0)
        
        if duration_hours >= self.upstream_stale_hours_threshold:
            return (
                SensorStatus.STALE,
                f"{station_name} flatlined for {duration_hours:.1f}h (>= {self.upstream_stale_hours_threshold:.1f}h threshold)",
                False
            )
        elif duration_hours > self.upstream_suspect_flatline_hours_threshold:
            return (
                SensorStatus.SUSPECT_FLATLINE,
                f"{station_name} prolonged invariant reading for {duration_hours:.1f}h (> {self.upstream_suspect_flatline_hours_threshold:.1f}h threshold)",
                False
            )
        elif duration_hours >= 6.0:
            if has_heavy_rain:
                return (
                    SensorStatus.SUSPECT_FLATLINE,
                    f"{station_name} invariant reading for {duration_hours:.1f}h despite heavy rainfall ({corroborating_rain:.1f}mm)",
                    False
                )
            return (
                SensorStatus.STABLE_BUT_PLAUSIBLE,
                f"{station_name} stable river stage for {duration_hours:.1f}h (consistent with natural baseflow)",
                True
            )
        else:
            return (
                SensorStatus.HEALTHY,
                f"{station_name} active with normal variance",
                True
            )

