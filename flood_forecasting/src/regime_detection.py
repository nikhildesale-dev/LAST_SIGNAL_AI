"""
LAST_SIGNAL_AI: Hydrological Regime Detection Module

Implements dual-regime detection with training-corroborated trigger logic
and timestamp-based hysteresis state management:
- BASEFLOW: Quiescent stage conditions; optimal for local stage persistence.
- SURGE: Active hydraulic pulses or corroborated rainfall bursts; optimal for Ridge Config C.
- DEGRADED: Fallback state when upstream telemetry drops out.
"""

from enum import Enum
from typing import Dict, List, Optional, Tuple, Union
import pandas as pd
import numpy as np


class HydrologicalRegime(str, Enum):
    BASEFLOW = "BASEFLOW"
    SURGE = "SURGE"
    DEGRADED = "DEGRADED"
    DEGRADED_UNUSABLE = "DEGRADED_UNUSABLE"


class RegimeDetector:
    """
    Stateful hydrological regime classifier using timestamp-based hysteresis.
    """

    def __init__(
        self,
        rain_sum_72h_threshold: float = 5.0,
        rain_intensity_threshold: float = 0.20,
        shigaon_delta_6h_threshold: float = 0.08,
        shigaon_delta_24h_threshold: float = 0.16,
        koyna_delta_24h_threshold: float = 0.10,
        holding_hours: int = 24
    ):
        self.rain_sum_72h_threshold = rain_sum_72h_threshold
        self.rain_intensity_threshold = rain_intensity_threshold
        self.shigaon_delta_6h_threshold = shigaon_delta_6h_threshold
        self.shigaon_delta_24h_threshold = shigaon_delta_24h_threshold
        self.koyna_delta_24h_threshold = koyna_delta_24h_threshold
        self.holding_duration = pd.Timedelta(hours=holding_hours)
        
        self.last_surge_trigger_timestamp: Optional[pd.Timestamp] = None

    def reset(self):
        """Reset internal hysteresis memory."""
        self.last_surge_trigger_timestamp = None

    def evaluate_step(
        self,
        features: Dict[str, Union[float, int, None]],
        current_time: pd.Timestamp
    ) -> Tuple[HydrologicalRegime, str, bool]:
        """
        Evaluate hydrological regime for a single timestamp.
        
        Returns:
            Tuple of:
                - HydrologicalRegime (BASEFLOW, SURGE)
                - Regime reason string
                - is_holding (bool: True if in hysteresis hold period)
        """
        # 1. Hydraulic stage surge triggers (Warna tributary or Koyna reservoir)
        s6 = features.get("shigaon_delta_6h")
        s24 = features.get("shigaon_delta_24h")
        k24 = features.get("koyna_delta_24h")
        
        trig_hydraulic = False
        triggers = []
        
        if (s6 is not None and pd.notna(s6) and s6 > self.shigaon_delta_6h_threshold) or \
           (s24 is not None and pd.notna(s24) and s24 > self.shigaon_delta_24h_threshold):
            trig_hydraulic = True
            triggers.append("warna_stage_rise")
            
        if k24 is not None and pd.notna(k24) and k24 > self.koyna_delta_24h_threshold:
            trig_hydraulic = True
            triggers.append("koyna_dam_surge")
            
        # 2. Corroborated rainfall triggers (requires upstream confirmation or extreme rain)
        r72 = features.get("rain_sum_72h")
        rint6 = features.get("rain_intensity_6h")
        
        has_rain = (r72 is not None and pd.notna(r72) and r72 > self.rain_sum_72h_threshold) or \
                   (rint6 is not None and pd.notna(rint6) and rint6 > self.rain_intensity_threshold)
                   
        trig_rainfall = False
        if has_rain:
            corroborated = (
                (s6 is not None and pd.notna(s6) and s6 > 0.02) or
                (k24 is not None and pd.notna(k24) and k24 >= 0.0) or
                (r72 is not None and pd.notna(r72) and r72 > 25.0)
            )
            if corroborated:
                trig_rainfall = True
                triggers.append("corroborated_rainfall_surge")
                
        is_active_trigger = trig_hydraulic or trig_rainfall
        
        # 3. Timestamp-based hysteresis state transition
        if is_active_trigger:
            self.last_surge_trigger_timestamp = current_time
            return HydrologicalRegime.SURGE, f"Surge trigger active ({'+'.join(triggers)})", False
            
        if self.last_surge_trigger_timestamp is not None:
            elapsed = current_time - self.last_surge_trigger_timestamp
            if elapsed <= self.holding_duration and elapsed >= pd.Timedelta(0):
                rem_h = (self.holding_duration - elapsed).total_seconds() / 3600.0
                return (
                    HydrologicalRegime.SURGE,
                    f"Hysteresis hold ({rem_h:.1f}h remaining from {self.last_surge_trigger_timestamp})",
                    True
                )
                
        return HydrologicalRegime.BASEFLOW, "Quiescent hydrological conditions", False

